package WebGUI::Asset::Wobject::Exporter::DataSource;

use strict;

use JSON qw{ from_json to_json };
use Data::Dumper;
use Tie::IxHash;
use base qw{ WebGUI::Crud };

sub _appendDynamicFormElements {
    my $self        = shift;
    my $f           = shift;
    my $elements    = shift || {};
    my $data        = shift;

    while ( my ($fieldName, $element) = each %{ $elements } ) {
        next if $element->{ noFormPost };

        $element->{ value   } = $data->{ $fieldName };
        $element->{ name    } = $fieldName;
        $f->dynamicField( %{$element} );
    }
}

sub create {
    my $class   = shift;
    my $self    = $class->SUPER::create( @_ );

    # Automatically set correct class name
    $self->update( {
        className   => ref $self,
    } );

    return $self;
}

sub crud_definition {
    my $class   = shift;
    my $session = shift;

    my $definition = $class->SUPER::crud_definition( $session );

    $definition->{ tableName    } = 'Exporter_dataSource';
    $definition->{ tableKey     } = 'dataSourceId';
    $definition->{ sequenceKey  } = 'assetId';

    $definition->{ properties   }->{ assetId        } = {
        fieldType   => 'hidden',
        noFormPost  => 1,
    };
    $definition->{ properties   }->{ className      } = {
        fieldType   => 'hidden',
        noFormPost  => 1,
    };
    $definition->{ properties   }->{ name           } = {
        fieldType   => 'text',
        label       => 'Name',
    };
    $definition->{ properties   }->{ description    } = {
        fieldType   => 'textarea',
        label       => 'Description',
    };
    $definition->{ properties   }->{ options        } = {
        fieldType   => 'textarea',
        noFormPost  => 1,
    };

    tie %{ $definition->{ options } }, 'Tie::IxHash';

    return $definition;
}

sub getEditForm {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;

    my $tabform = WebGUI::TabForm->new( $session );
    $tabform->hidden( {
        name    => 'dataSourceId',
        value   => $form->process('dataSourceId') || $self->getId,
    } );
    $tabform->hidden( {
        name    => 'className',
        value   => ref $self,
    } );
    
    # Properties tab
    my $properties  = $tabform->addTab( 'properties', 'Base properties' );
    $self->_appendDynamicFormElements( $properties, $self->crud_definition( $session )->{ properties }, $self->get );

    # Options tab
    my $options     = $tabform->addTab( 'options', 'Configuration options' );
    $self->_appendDynamicFormElements( $options, $self->crud_definition( $session )->{ options }, $self->getOption );

    return $tabform;
}

sub getOption {
    my $self    = shift;
    my $key     = shift;

    my $options = from_json( $self->get( 'options' ) || '{}' );

    if ( $key ) {
        my $value = $options->{ $key };
        if ( wantarray ) {
            return () unless defined $value;
            return 
                ref $value eq 'ARRAY'
                ? @{ $value }
                :  ( $value )
            ;
        }

        return $value;
    }
    
    return $options;
}

sub getSql {

};

sub newByDynamicClass {
    my $class           = shift;
    my $session         = shift;
    my $dataSourceId    = shift;

    my $className = $session->db->quickScalar( 'select className from Exporter_dataSource where dataSourceId=?', [
        $dataSourceId,
    ] );
    unless ($className) {
        $session->log->warn( "Could not find class for data source [$dataSourceId]" );
        return undef;
    }

    my $self = eval { WebGUI::Pluggable::instanciate( $className, 'new', [ $session, $dataSourceId ] ) };
    if ($@) {
        $session->log->warn( "Could not instanciate data source [$dataSourceId] of class [$className] because: $@" );
        return undef;
    }

    return $self;
}

sub processRecord {

};

sub updateFromFormPost {
	my $self    = shift;
	my $session = $self->session;
	my $form    = $session->form;

	my $propertyData    = {};
	my $properties      = $self->crud_getProperties( $session );
    my $optionData      = {};
    my $options         = $self->crud_definition( $session )->{ options };

	foreach my $fieldName ( keys( %$properties ), keys( %$options ) ) {
		my @value = $form->process( 
            $fieldName, 
            $properties->{ $fieldName }->{ fieldType }, 
            $properties->{ $fieldName }->{ defaultValue },
        );
        my $value   = scalar @value > 1
                    ? \@value
                    : $value[ 0 ]
                    ;

        if ( exists $properties->{ $fieldName } && !$properties->{ $fieldName }->{ noFormPost } ) {
            $propertyData->{ $fieldName } = $value;
        }
        if ( exists $options->{ $fieldName } && !$options->{ $fieldName }->{ noFormPost } ) {
            $optionData->{ $fieldName } = $value;
        }
	}

    $self->updateOptions( $optionData );

	return $self->update( $propertyData );

}

sub updateOptions {
    my $self = shift;
    my $data = shift;

    my $options = from_json( $self->get('options') || '{}' );
    $options = { %{$options}, %{ $data } };
    $self->update( { options => to_json( $options ) } );
}

1;
