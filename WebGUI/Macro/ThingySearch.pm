package WebGUI::Macro::ThingySearch;

use strict;

use WebGUI::Asset::Wobject::Thingy;
use WebGUI::Asset::Template;

#--------------------------------------------------------------
sub process {
    my $session     = shift;
    my $thingyId    = shift || return 'ThingyId required';
    my $templateId  = shift || return 'TemplateId required';

    my $thingy = WebGUI::Asset::Wobject::Thingy->new( $session, $thingyId );
    return 'Invalid thingyId' unless $thingy && $thingy->isa( 'WebGUI::Asset::Wobject::Thingy' );

    my $thingId = $thingy->get('defaultThingId');
    return 'Cannot search this thing' unless $thingy->canSearch( $thingId );

    my $var = $thingy->getSearchTemplateVars( $thingId );

    # Un-loop search fields.
    $var->{ allSearchFieldsQueried } = 1;
    foreach my $searchField ( @{ $var->{ searchFields_loop } } ) {
        my $label = $searchField->{ searchFields_label };

        foreach my $searchFieldProperty ( keys %{ $searchField } ) {
            $var->{ $searchFieldProperty . '_' . $label } = $searchField->{ $searchFieldProperty };
        }

        my $fieldProperties = $session->db->quickHashRef( 'select * from Thingy_fields where fieldId = ?', [
           $searchField->{ searchFields_fieldId } 
        ]);

        my $plugin = $thingy->getFormPlugin( $fieldProperties, 1);

        $var->{ "searchQuery_$label"    } = $plugin->getValueAsHtml;
        $var->{ allSearchFieldsQueried  } = 0 unless $plugin->getValue;
    }

    # Build lookup table for fieldIds -> field labels
    my $fieldLabel = {};
    foreach my $field ( @{ $var->{ displayInSearchFields_loop } } ) {
        $fieldLabel->{ $field->{ displayInSearchFields_fieldId } } = $field->{ displayInSearchFields_label };
    }

    # Un-loop fields in search results.
    my $previousResult = {};
    foreach my $result ( @{ $var->{ searchResult_loop } } ) {
        foreach my $field ( @{ $result->{ searchResult_field_loop } } ) {
            my $label = $fieldLabel->{ $field->{ field_id } };
            $result->{ "field_value_$label" } = $field->{ field_value };
            if ( $previousResult->{ "field_value_$label" } ne $field->{ field_value } ) {
                $result->{ "field_value_changed_$label" } = 1;
            }
        }

        $previousResult = $result;
    }

    my $template = WebGUI::Asset::Template->new( $session, $templateId );
    return 'invalid assetId' unless $template && $template->isa( 'WebGUI::Asset::Template' );

    return $template->process( $var );
}

1;

