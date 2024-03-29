package WebGUI::Macro::DFTabRoute;

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
    my $ordering    = shift || 'sequential';
    my @tabs        = @_;

    my $dataStore = WebGUI::Asset::Wobject::DataForm::RoutedQuestions->new( $session, $dataStoreId );
    return 'Could not instatiate RoutedQuestions asset' unless $dataStore;

    my $template = WebGUI::Asset::Template->new( $session, $templateId );
    return 'Could not instanciate Template asset' unless $template;

    my $route = $dataStore->getRoute;
    
    my $tabCounter = 0;
    my @tabLoop;
    my $var;

    $var->{ allTabsComplete } = 1;
    foreach my $tabId ( @{ $route->{ tabOrder } } ) {
        my $tab     = $dataStore->getTabConfig( $tabId );
        my $name    = $tab->{ label };
        $name =~ s/ /_/g;

        $tab->{ "nameIs$name"   } = 1;
        $tab->{ isAssetTab      } = $session->asset->getId eq $tab->{ assetLink };
        $tab->{ isComplete      } = $dataStore->tabComplete( $tabId );
        $tab->{ isCurrent       } = $tabCounter == $route->{ currentTab };
        $tab->{ tabCount        } = $tabCounter;

        if ( $tab->{ assetLink } ) {
            my $linkedAsset = WebGUI::Asset->newByDynamicClass( $session, $tab->{ assetLink } );
            $tab->{ linkAssetUrl    } = $linkedAsset->getUrl;

        }

        unless ( $tab->{ isComplete  } ) {
            $var->{ allTabsComplete } = 0;
        }

        push @tabLoop, $tab;

        if ( !$tab->{ isComplete } && !$var->{'nextStep_tabId'} ) {
            $var = { 
                %$var, 
                map { ( "nextStep_$_" => $tab->{ $_ } ) } keys %{ $tab } 
            }; 
        }

        $tabCounter++;
    }

$session->log->warn( Dumper( \@tabLoop ) );
$session->log->warn( Dumper( $dataStore->getFieldOrder ) );
$session->log->warn( Dumper( $dataStore->getFieldConfig ) );
    $var->{ tab_loop } = \@tabLoop;

    return $template->process( $var );
}

1;

