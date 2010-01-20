package WebGUI::Form::WaskoLokatie;

use strict;
use base 'WebGUI::Form::SelectBox';
use Tie::IxHash;

=head1 NAME

Package WebGUI::Form::WaskoLokatie

=head1 DESCRIPTION

Creates a Wasko lokatie selectbox.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::SelectBox.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 areOptionsSettable ( )

Returns 0.

=cut

sub areOptionsSettable {
    return 0;
}

#-------------------------------------------------------------------

=head2 definition ( [ additionalTerms ] )

See the super class for additional details.

=head3 additionalTerms

The following additional parameters have been added via this sub class.

=head4 name

The identifier for this field. Defaults to "--selecteer--".

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift || [];
	push(@{$definition}, {
		label=>{
			defaultValue=>'lokatie'
			},
		name=>{
			defaultValue=>"WaskoLokatie"
			},
		defaultValue=>{
			defaultValue=>"--selecteer--"
			},
        });
        return $class->SUPER::definition($session, $definition);
}

sub getOptions {
    my $self    = shift;
    my %locaties = $self->session->db->buildHash('
                SELECT distinct(`field_IbYnuRjC5MRW3mNpxZ2RtQ`),`field_IbYnuRjC5MRW3mNpxZ2RtQ`
                FROM `Thingy_a-L_jtGu8UMujgYpNTtCBg`'
            );
    return \%locaties;
}
#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this control.

=cut

sub getName {
    my ($self, $session) = @_;
    return 'WaskoLokatie';
}

#-------------------------------------------------------------------

=head2 isDynamicCompatible ( )

A class method that returns a boolean indicating whether this control is compatible with the DynamicField control.

=cut

sub isDynamicCompatible {
    return 1;
}


1;
