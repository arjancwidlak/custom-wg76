package WebGUI::Macro::DFTabForm;

use strict;

use WebGUI::Asset::Wobject::DataForm::RoutedQuestions;
use WebGUI::Asset::Template;
use List::Util qw{ shuffle };
use JSON qw{ from_json to_json };
use Data::Dumper;

sub process {
    my $session     = shift;
    my $dataStoreId = shift;
    my $templateId  = shift || return 'TemplateId is required';
    my @tabs        = @_;

    my $dataStore = WebGUI::Asset::Wobject::DataForm::RoutedQuestions->new( $session, $dataStoreId );
    return 'Could not instatiate RoutedQuestions asset' unless $dataStore;

    my $template = WebGUI::Asset::Template->new( $session, $templateId );
    return 'Could not instanciate Template asset' unless $template;

    my $assetTab    = $dataStore->getTabByAssetLink( $session->asset->getId );
    my $currentTab  = $dataStore->getTabByLastCompleted;

    my $entry       = $dataStore->getUserEntry;
    my $assetVars   = $dataStore->getRecordTemplateVars( {}, $entry );

#    (my $var) = grep { $_->{'tab.tid'} eq $tab->{tabId} } @{ $vars->{tab_loop} };
    my @tabLoop;
    foreach my $tab( @{ $assetVars->{tab_loop} } ) {
        my $name = $tab->{'tab.name'};

        $tab->{ isComplete      } = $dataStore->tabComplete( $tab->{'tab.tid'} );
        $tab->{ isCurrent       } = $tab->{'tab.tid'} eq $currentTab->{tabId};
        $tab->{ isAssetTab      } = $tab->{'tab.tid'} eq $assetTab->{tabId};
        $tab->{ "nameIs$name"   } = 1;
        $tab->{ form_header     } = 
            WebGUI::Form::formHeader( $session, { action => $dataStore->getUrl } )
            . WebGUI::Form::hidden( $session, { name => 'func', value => 'processTabData' } )
            . WebGUI::Form::hidden( $session, { name => 'tabId', value => $tab->{'tab.tid'} } );
        $tab->{ form_submit     } = WebGUI::Form::submit( $session );
        $tab->{ form_footer     } = WebGUI::Form::formFooter( $session );

        push @tabLoop, $tab;
    }

    my $var;
    $var->{ tab_loop } = \@tabLoop;

    return $template->process( $var );
}

1;

