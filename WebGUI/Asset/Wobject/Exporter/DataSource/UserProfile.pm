package WebGUI::Asset::Wobject::Exporter::DataSource::UserProfile;

use strict;

use WebGUI::ProfileField;
use Data::Dumper;

use base qw{ WebGUI::Asset::Wobject::Exporter::DataSource };

#-------------------------------------------------------------------
sub crud_definition {
    my $class   = shift;
    my $session = shift;

    my $definition = $class->SUPER::crud_definition( $session );

    $definition->{ options }->{ excludeGroups } = {
        fieldType       => 'group',
        label           => 'Exclude users in group(s)',
        multiple        => 1,
        defaultValue    => [ ' ' ],
        size            => 5,
        excludeGroups   => [ qw{ 1 2 7 } ], 
    };
    $definition->{ options }->{ includeGroups } = {
        fieldType       => 'group',
        label           => 'Include users in group(s)',
        multiple        => 1,
        defaultValue    => [ ' ' ],
        size            => 5,
        excludeGroups   => [ qw{ 1 2 7 } ], 
    };
    $definition->{ options }->{ includeFields } = {
        noFormPost  => 1,
    };

    return $definition;
}

#-------------------------------------------------------------------
sub getColumnCount {
    my $self = shift;

    return scalar @{ $self->getOption('includeFields') || [] };
}

#-------------------------------------------------------------------
sub getEditForm {
    my $self = shift;
    my $session = $self->session;
    my ($style, $url) = $session->quick( qw{ style url } );

    $style->setScript($url->extras('yui/build/yahoo-dom-event/yahoo-dom-event.js'));
    $style->setScript($url->extras('yui/build/animation/animation-min.js'));
    $style->setScript($url->extras('yui/build/dragdrop/dragdrop-min.js'));
    $style->setScript($url->extras('exporter/exporter.js'));
    $style->setRawHeadTags( <<'EOJS' );
    <style type="text/css">
        .ddList {
            border: 1px solid black;
            background: #dddddd;
            border-collapse: collapse;
            min-height: 50px;
        }
        tr.ddItem {
            border: 1px solid black;
            background: #eee;
            min-height: 50px;
        }
    </style>
    <script type="text/javascript">
        YAHOO.util.Event.onDOMReady( function () {
            YAHOO.example.DDApp.init( [ 'options', 'includeFields' ] );
        })
    </script>
EOJS

    my (@enabled, @disabled);
    my %includedFields =  map { $_->{ fieldId } => $_ } @{ $self->getOption( 'includeFields' ) || []};
    my $fields  = WebGUI::ProfileField->getFields( $session );
    foreach my $field (@{ $fields } ) {
        if ( exists $includedFields{ $field->getId } ) {
            push @enabled, $field;
        }
        else {
            push @disabled, $field;
        }
    }

    my $formatTr = sub {
        my $field = shift;
        return
            '<tr class="ddItem" valign="top">'
            .'<td>'.$field->getLabel.'</td><td>'.$field->getId.'</td>'
            .'<td>'.WebGUI::Form::hidden( $session, { name=>"includeField", value => $field->getId } )
            . 'Use label in header?' 
            . WebGUI::Form::yesNo( $session, { name => 'labelIsHeader_'.$field->getId, value => $includedFields{ $field->getId }{ labelIsHeader } } )
            . '</td>'
            . '<td>Display raw value?'
            . WebGUI::Form::yesNo( $session, { name => 'displayRawValue_'.$field->getId, value => $includedFields{ $field->getId }{ displayRawValue } } )
            .'</tr>';
    };
    my $table = 
        '<table border="0">'
        . '<tr><th>Enabled</th><th>Disabled</th></tr>'
        . '<tr valign="top" height="100%">'
        .   '<td width="50%">'
        .       '<table cellspacing="10" class="ddList" id="includeFields" width="100%" height="50">'
        .       join( '', map { $formatTr->($_) } @enabled )
        .       '</table>'
        .   '</td>'
        .   '<td width="50%">'
        .       '<table cellspacing="10" class="ddList" id="options" width="100%" height="50">'
        .       join( '', map { $formatTr->($_) } @disabled )
        .       '</table>'
        .   '</td>'
        . '</tr>'
        . '</table>';

    my $tabform = $self->SUPER::getEditForm;
    $tabform->getTab('options')->readOnly(
        label   => 'Fields',
        value   => $table,
    );

    return $tabform;
};

#-------------------------------------------------------------------
sub getFieldLabels {
    my $self    = shift;
    my $session = $self->session;

    my @labels;
    foreach my $fieldConfig ( @{ $self->getOption('includeFields') || [] } ) {
        my $profileField = WebGUI::ProfileField->new( $session, $fieldConfig->{ fieldId } );
        push @labels, $fieldConfig->{ labelIsHeader } ? $profileField->getLabel : $profileField->getId;
    }

    return @labels;
}

#-------------------------------------------------------------------
sub getSql {
    my $self    = shift;
    my $alias   = shift;
    my $dbh     = $self->session->db->dbh;

    my @fields = @{ $self->getOption( 'includeFields' ) || [] };

    my @select      = map { $_->{ fieldId } } @fields;
    my $table       = 'userProfileData';    
    my $joinColumn  = 'userId';
    my @where       = ();

    my @exclude = $self->getOption( 'excludeGroups' );
    if ( @exclude ) {
        my $exclude = join q{,}, map { $dbh->quote( $_ ) } @exclude ;
        push @where, $dbh->quote_identifier( $alias, 'userId') . " not in "
            . "( select userId from groupings where groupId in ( $exclude ) )";
    }
    my @include = $self->getOption( 'includeGroups' );
    if ( @include ) {
        my $include = join q{,}, map { $dbh->quote( $_ ) } @include ;
        push @where, $dbh->quote_identifier( $alias, 'userId') . " in "
            . "( select userId from groupings where groupId in ( $include ) )";
    }
    
    return ( \@select, $table, $joinColumn, join( ' AND ', @where ) );
}

#-------------------------------------------------------------------
sub processFieldData {
    my $self    = shift;
    my @rawData = @_;
    my $session = $self->session;
    my @processedData;

    my $index = 0;
    foreach my $fieldConfig ( @{ $self->getOption('includeFields') } ) {
        my $profileField    = WebGUI::ProfileField->new( $session, $fieldConfig->{ fieldId } );
        my $rawValue        = defined $rawData[ $index ] ? $rawData[ $index ] : "";

        push @processedData, 
            $fieldConfig->{ displayRawValue } 
                ? $rawValue
                : $profileField->formField( undef, 2, undef, 0, $rawValue )
                ;

        $index++;
    }

    return @processedData;
}

#-------------------------------------------------------------------
sub updateFromFormPost {
    my $self = shift;
    my $session = $self->session;
    my $form = $session->form;

    $self->SUPER::updateFromFormPost( @_ );

    my @fieldIndexes = 
        sort    {$a <=> $b}
        grep    { s{^includeField_(\d+)$}{$1} }
        $form->param;

    my @includeFields;
    foreach my $index ( @fieldIndexes ) {
        my $fieldId = $form->process( "includeField_$index" );
        push @includeFields, {
            fieldId         => $fieldId,
            displayRawValue => $form->process( "displayRawValue_$fieldId\_$index" ),
            labelIsHeader   => $form->process( "labelIsHeader_$fieldId\_$index" ),
        }
    }

    $self->updateOptions( { includeFields => \@includeFields } );
}

1;

