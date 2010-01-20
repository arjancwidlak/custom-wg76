package WebGUI::Asset::Wobject::NoteDropper::Note;

use strict;

use base qw{ WebGUI::Crud };

sub crud_definition {
	my ($class, $session) = @_;
	my $definition = $class->SUPER::crud_definition($session);

    my $properties = {
        assetId => {
            fieldType       => 'asset',
        },
        rating  => {
            fieldType       => 'integer',
            defaultValue    => 0,
        },
        userId  => {
            fieldType       => 'user',
        },
        title   => {
            fieldType       => 'text',
        },
        content => {
            fieldType       => 'textarea',
        },
    };

    # Userdefined fields
    for ( 1 .. 5 ) {
        $properties->{ "userDefined$_" } = {
            fieldType   => 'textarea',
        }
    }

    my $definition = {
        tableName   => 'NoteDropper_notes',
        tableKey    => 'noteId',
        properties  => $properties,
    };

	return $definition;
}

1;

