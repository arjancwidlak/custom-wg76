package WebGUI::Macro::MetaData;

use strict;

use WebGUI::Asset;
use WebGUI::Asset::Template;
use WebGUI::Operation::Shared;
use WebGUI::International;

#---------------------------------------------------
sub process {
    my $session     = shift;
    my $assetId     = shift;
    my $templateId  = shift;

    # Instanciate asset
    my $asset;
    if ($assetId eq 'new') {
        my $className = $session->form->process('class') || 'WebGUI::Asset';
        $asset = WebGUI::Asset->newByPropertyHashRef( $session, { className => $className } );
    }
    else {
        $asset = WebGUI::Asset->newByDynamicClass( $session, $assetId );
        return "Could not instanciate asset with id [$assetId]" unless $asset;
    }

    # Instanciate template
    my $template = WebGUI::Asset::Template->new( $session, $templateId );
    return "Could not instanciate template with id [$templateId]" unless $template;

    # Fetch metaData
    my $metaData = $asset->getMetaDataFields;

    # Create loop
    my $var = {};
    my @metaLoop;
    foreach my $id ( keys %{ $metaData } ) {
	my $values;
        my $meta = $metaData->{ $id };
        (my $fieldName = $meta->{ fieldName}) =~ tr/ /_/;

        # Setup options for multiple values
        tie my %options, 'Tie::IxHash';

	if(($meta->{possibleValues} =~ m/{/) && ($meta->{possibleValues} =~ m/}/)){ 
	        $values = WebGUI::Operation::Shared::secureEval( $session, $meta->{possibleValues} );
	}
	else{
		$values = $meta->{possibleValues};
	}
        if (ref $values eq 'HASH') {
            %options = %{$values};
        }
        else {
            %options = 
                map     { s/\s+$//; $_ => $_ }          # Turn into hash ref 
                sort
                split   /\n/, $meta->{ possibleValues } # Split possible values
                ;   
        }

        # Append select a value message for selectBoxes
        %options = ("" => WebGUI::International->new($session, 'Asset')->get('Select'), %options) 
            if $meta->{ fieldType } eq 'selectBox';

        # Create form element
        my $form = WebGUI::Form::dynamicField( $session, 
            fieldType       => $meta->{ fieldType } || 'text',
            name            => "metadata_$id",
            value           => $meta->{ value },
            options         => \%options,
            extras          => qq|title="$meta->{description}"|,
        );

        $var->{ $fieldName              } = $meta->{ value };
        $var->{ $fieldName . '_display' } = $options{ $meta->{ value } } || $meta->{ value };
        $var->{ $fieldName . '_form'    } = $form;
        $var->{ $fieldName . '_id'      } = $id;
        
        push @metaLoop, {
            "name_is_$fieldName"    => 1,
            "id"                    => $id,
            "name"                  => $meta->{ fieldName },
            "value"                 => $meta->{ value },
            "display"               => $options{ $meta->{ value } } || $meta->{ value },
            "form"                  => $form,
            "value_loop"            => [ 
                map     { {value => $_} } 
                sort
                split   /\n/, $meta->{ value } 
            ],
        }
    }
    $var->{ meta_loop } = \@metaLoop;

    return $template->process( $var );
}

1;

