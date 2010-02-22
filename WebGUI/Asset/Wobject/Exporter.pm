package WebGUI::Asset::Wobject::Exporter;

$VERSION = "0.0.1";

use strict;

use Tie::IxHash;
use WebGUI::International;
use WebGUI::Utility;
use WebGUI::Asset::Wobject::Exporter::DataSource;
use Spreadsheet::Write;

use Data::Dumper;
use base 'WebGUI::Asset::Wobject';

#-------------------------------------------------------------------
sub buildQuery {
    my $self    = shift;
    my $session = $self->session;
    my $dbh     = $session->db->dbh;

    my $dataSources = $self->getDataSources;

    my $debug;
    my ( @aliases, @select, @tables, @joinOn, @where );
    foreach my $ds ( @{ $dataSources } ) {
        my $alias = $ds->getId;
        my ($columns, $table, $joinColumn, $constraints) = $ds->getSql( $alias );

        # Don't bother processing this data source if it doesn't retrieve any data
        next unless scalar @{ $columns };

        push @aliases, $alias;
        push @select, map { $dbh->quote_identifier( $alias, $_ ) } @{ $columns };
        push @tables, $table;
        push @joinOn, $joinColumn;
        push @where, $constraints if $constraints;
       
        $debug .= Dumper( [ $ds->getSql ] );
    };

    my $select  = join ', ', @select;
    my $from    = $dbh->quote_identifier( $tables[ 0 ] ) . ' as ' . $dbh->quote_identifier( $aliases[ 0 ] );
    for my $i ( 1 .. scalar @tables - 1 ) {
        $from   .= " left join "
                . $dbh->quote_identifier( $tables[ $i ] ) 
                . ' as ' 
                . $dbh->quote_identifier( $aliases[ $i ] )
                . ' on '
                . $dbh->quote_identifier( $aliases[ $i - 1 ], $joinOn[ $i - 1 ] )
                . ' = '
                . $dbh->quote_identifier( $aliases[ $i ], $joinOn[ $i ] )
                ;
    }
    
    my $where = '(' . join( ' ) and ( ', @where ) . ')' if scalar @where;

    my $sql = "SELECT $select FROM $from ";
    $sql .= " WHERE $where " if $where;

    return $sql;
}

#-------------------------------------------------------------------
sub definition {
	my $class       = shift;
	my $session     = shift;
	my $definition  = shift;
	my $i18n        = WebGUI::International->new($session, 'Asset_Exporter');

	tie my %properties, 'Tie::IxHash', (
        templateId => {
			fieldType       => 'template',  
 		    defaultValue    => 'qn5FFjaslZH-lo3mhqv59w',
			tab             => 'display',
			namespace       => 'Exporter', 
			hoverHelp       => $i18n->get( 'templateId label description' ),
			label           => $i18n->get( 'templateId label' ),
		}
	);
	push(@{$definition}, {
		assetName           => $i18n->get( 'assetName' ),
		icon                => 'newWobject.gif',
		autoGenerateForms   => 1,
		tableName           => 'Exporter',
		className           => 'WebGUI::Asset::Wobject::Exporter',
		properties          =>  \%properties
    });

    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------
sub getEnabledDataSources {
    return { 
        'WebGUI::Asset::Wobject::Exporter::DataSource::UserProfile'     => 'User profile',
        'WebGUI::Asset::Wobject::Exporter::DataSource::DataForm'        => 'DataForm',
        'WebGUI::Asset::Wobject::Exporter::DataSource::RoutedQuestions' => 'RoutedQuestions',
    };
}

#-------------------------------------------------------------------
sub getDataSourceFromFormPost {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;

    my $dataSourceId    = $form->process( 'dataSourceId' );
    my $className       = $form->process( 'className' );
    
    my $plugins = [ keys %{ $self->getEnabledDataSources } ];

    my $dataSource;
    if ( $dataSourceId eq 'new' ) {
        unless ( grep { $_ eq $className } @{ $plugins } ) {
            $session->log->warn( "illegal classname [$className]" );
            return undef;
        };

        # Create a datasource tied to this assetId.
        $dataSource = eval { WebGUI::Pluggable::instanciate( $className, 'create', [ $session, { assetId => $self->getId } ] ) };
        if ( $@ ) {
            $session->log->warn( "could not create a new data source because: $@" );
            return undef;
        }
    }
    else {
        $dataSource = WebGUI::Asset::Wobject::Exporter::DataSource->newByDynamicClass( $session, $dataSourceId );
    }
    $session->log->warn( "could not instaciate datasource [$dataSourceId]" ) unless $dataSource;

    return $dataSource;
}

#-------------------------------------------------------------------
sub getDataSources {
    my $self    = shift;
    my $session = $self->session;

    my $ids = WebGUI::Asset::Wobject::Exporter::DataSource->getAllIds( $session, { 
        sequenceKeyValue => $self->getId 
    } );

    my @dataSources =
        map { WebGUI::Asset::Wobject::Exporter::DataSource->newByDynamicClass( $session, $_ ) }
        @{ $ids };

    return \@dataSources;
}

#-------------------------------------------------------------------
sub prepareView {
    my $self = shift;
    $self->SUPER::prepareView();

    my $template = WebGUI::Asset::Template->new( $self->session, $self->get("templateId") );
    $template->prepare;

    $self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------
sub processData {
    my $self            = shift;
    my $addHeaderRow    = shift;
    my $addRow          = shift;
    my $session         = $self->session;
    my $db              = $session->db;
    
    my $dataSources = $self->getDataSources;
   
    # Fetch headers
    my @headers = map { $_->getFieldLabels } @{ $dataSources };
    $addHeaderRow->( @headers );

    # Fetch and process data
    my $sth = $db->read( $self->buildQuery );
    while (my @row = $sth->array) {
        my $index = 0;
        my @processedData;
        foreach my $ds ( @{ $dataSources } ) {
            push @processedData, $ds->processFieldData( @row[ $index .. $index + $ds->getColumnCount - 1 ] );

            $index += $ds->getColumnCount;
        }

        $addRow->( @processedData );
    }
}

#-------------------------------------------------------------------
sub www_exportAsHtml {
    my $self    = shift;
    my $session = shift;

    return $session->privilege->insufficient unless $self->canView;

    my $output = '<table border="1">';

    # Callback functions for adding headers and row to the table;
    my $addHeader = sub {
        $output .= '<tr><th>'. join('</th><th>', @_).'</th></tr>';
    };
    my $addRow = sub {
        $output .= '<tr><td>'. join('</td><td>', @_).'</td></tr>';
    };
    
    # Add the data to our table
    $self->processData( $addHeader, $addRow );

    $output .= '</table>';

    return $output;
}

#-------------------------------------------------------------------
sub _writeSpreadsheet {
    my $self    = shift;
    my $format  = shift;
    my $session = $self->session;

    $format = 'xls' unless $format eq 'csv';
    my $storage = WebGUI::Storage->createTemp( $session );

    my $writer = Spreadsheet::Write->new( 
        file        => $storage->getPath( "export.$format" ),
        format      => $format,
        encoding    => 'utf-8',
    );

    my $addRow = sub {
        $writer->addrow( map { { content => $_ } } @_ );
    };

    $self->processData( $addRow, $addRow );

    return $storage->getUrl( "export.$format" );
}

#-------------------------------------------------------------------
sub www_exportAsCsv {
    my $self    = shift;
    my $session = $self->session;
    my $http    = $session->http;

    return $session->privilege->insufficient unless $self->canView;

    my $url = $self->_writeSpreadsheet( 'csv' );

    $http->setMimeType( 'text/csv' );
    $http->setRedirect( $url );
}

#-------------------------------------------------------------------
sub www_exportAsXls {
    my $self    = shift;
    my $session = $self->session;
    my $http    = $session->http;

    return $session->privilege->insufficient unless $self->canView;

    my $url = $self->_writeSpreadsheet( 'xls' );

    $http->setMimeType( 'application/excel' );
    $http->setRedirect( $url );
}

#-------------------------------------------------------------------
sub purge {
	my $self = shift;
	#purge your wobject-specific data here.  This does not include fields 
	# you create for your NewWobject asset/wobject table.
	return $self->SUPER::purge;
}

#-------------------------------------------------------------------
sub view {
	my $self    = shift;
	my $session = $self->session;	

    my ($db, $icon) = $session->quick( qw{ db icon } );
	my $var     = $self->get;
	

    my $var = $self->get;
    $var->{ canEdit             } = $self->canEdit;
    $var->{ showAdmin           } = $self->canEdit && $session->var->isAdminOn;

    my $plugins = $self->getEnabledDataSources; 
    $var->{ addDataSource_form  } = 
        WebGUI::Form::formHeader( $session, { action => $self->getUrl } )
        . WebGUI::Form::hidden( $session,   { name => 'func',           value => 'editDataSource'   } )
        . WebGUI::Form::hidden( $session,   { name => 'dataSourceId',   value => 'new'              } ) 
        . WebGUI::Form::selectBox( $session,{ name => 'className',      options => $plugins         } )
        . WebGUI::Form::submit( $session )
        . WebGUI::Form::formFooter( $session );

    my $dataSources = $self->getDataSources;
    my @sources;
    foreach my $ds ( @{ $dataSources } ) {
        push @sources, {
            source_controls =>
                $icon->edit(       'func=editDataSource;dataSourceId='    . $ds->getId, $self->getUrl )
                . $icon->delete(   'func=deleteDataSource;dataSourceId='  . $ds->getId, $self->getUrl )
                . $icon->moveDown( 'func=demoteDataSource;dataSourceId='  . $ds->getId, $self->getUrl )
                . $icon->moveUp(   'func=promoteDataSource;dataSourceId=' . $ds->getId, $self->getUrl ),
            source_name     => $ds->get( 'name' ),
        }
    }
   
    $var->{ sources_loop    } = \@sources;
    $var->{ export_html_url } = $self->getUrl( 'func=exportAsHtml'  );
    $var->{ export_xls_url  } = $self->getUrl( 'func=exportAsXls'   );
    $var->{ export_csv_url  } = $self->getUrl( 'func=exportAsCsv'   );

	return $self->processTemplate($var, undef, $self->{_viewTemplate});
}

#-------------------------------------------------------------------
sub www_deleteDataSource {
    my $self    = shift;
    my $session = $self->session;

    return $session->privilege->adminOnly unless $self->canEdit;

    my $dataSource = $self->getDataSourceFromFormPost;
    $dataSource->delete;

    return $self->www_view;
}

#-------------------------------------------------------------------
sub www_demoteDataSource {
    my $self    = shift;
    my $session = $self->session;

    return $session->privilege->adminOnly unless $self->canEdit;

    my $dataSource = $self->getDataSourceFromFormPost;
    $dataSource->demote;

    return $self->www_view;
}

#-------------------------------------------------------------------
sub www_editDataSource {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;

    return $session->privilege->adminOnly unless $self->canEdit;

    my $dataSource = $self->getDataSourceFromFormPost;

    my $tabform = $dataSource->getEditForm;
    $tabform->hidden( {
        name    => 'func',
        value   => 'editDataSourceSave',
    } );
    $tabform->submit;

    if ( $form->get( 'dataSourceId' ) eq 'new' ) {
        $dataSource->delete;
    }

    return $self->processStyle( $tabform->print );
}

#-------------------------------------------------------------------
sub www_editDataSourceSave {
    my $self    = shift;
    my $session = $self->session;

    return $session->privilege->adminOnly unless $self->canEdit;

    my $dataSource = $self->getDataSourceFromFormPost;
    $dataSource->updateFromFormPost;

    return $self->www_view;
}

#-------------------------------------------------------------------
sub www_promoteDataSource {
    my $self    = shift;
    my $session = $self->session;

    return $session->privilege->adminOnly unless $self->canEdit;

    my $dataSource = $self->getDataSourceFromFormPost;
    $dataSource->promote;

    return $self->www_view;
}

#-------------------------------------------------------------------
# Everything below here is to make it easier to install your custom
# wobject, but has nothing to do with wobjects in general
#-------------------------------------------------------------------
# cd /data/WebGUI/lib
# perl -MWebGUI::Asset::Wobject::NewWobject -e install www.example.com.conf [ /path/to/WebGUI ]
# 	- or -
# perl -MWebGUI::Asset::Wobject::NewWobject -e uninstall www.example.com.conf [ /path/to/WebGUI ]
#-------------------------------------------------------------------


use base 'Exporter';
our @EXPORT = qw(install uninstall);
use WebGUI::Session;

#-------------------------------------------------------------------
sub install {
	my $config = $ARGV[0];
	my $home = $ARGV[1] || "/data/WebGUI";
	die "usage: perl -MWebGUI::Asset::Wobject::NewWobject -e install www.example.com.conf\n" unless ($home && $config);
	print "Installing asset.\n";
	my $session = WebGUI::Session->open($home, $config);
	$session->config->addToArray("assets","WebGUI::Asset::Wobject::NewWobject");
	$session->db->write("create table NewWobject (
		assetId varchar(22) binary not null,
		revisionDate bigint not null,
		primary key (assetId, revisionDate)
		)");
	$session->var->end;
	$session->close;
	print "Done. Please restart Apache.\n";
}

#-------------------------------------------------------------------
sub uninstall {
	my $config = $ARGV[0];
	my $home = $ARGV[1] || "/data/WebGUI";
	die "usage: perl -MWebGUI::Asset::Wobject::NewWobject -e uninstall www.example.com.conf\n" unless ($home && $config);
	print "Uninstalling asset.\n";
	my $session = WebGUI::Session->open($home, $config);
	$session->config->deleteFromArray("assets","WebGUI::Asset::Wobject::NewWobject");
	my $rs = $session->db->read("select assetId from asset where className='WebGUI::Asset::Wobject::NewWobject'");
	while (my ($id) = $rs->array) {
		my $asset = WebGUI::Asset->new($session, $id, "WebGUI::Asset::Wobject::NewWobject");
		$asset->purge if defined $asset;
	}
	$session->db->write("drop table NewWobject");
	$session->var->end;
	$session->close;
	print "Done. Please restart Apache.\n";
}


1;
#vim:ft=perl