package WebGUI::Dating::Date;

=head1 LEGAL

 -------------------------------------------------------------------
  Thingy is Copyright 2008 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Crud';
use Class::InsideOut qw(readonly private id register);
use WebGUI::International;

#private objectData => my %objectData;

#-------------------------------------------------------------------

=head2 crud_definition

WebGUI::Crud definition for this class.

=head3 tableName

Dates

=head3 tableKey

dateId

=head3 sequenceKey

None. Dates have no sequence amongst themselves.

=cut
sub crud_definition {
    my ($class, $session) = @_;
    #my $i18n = WebGUI::International->new($session, "Date");

    my $definition = $class->SUPER::crud_definition($session);
    $definition->{tableName} = 'Dates';
    $definition->{tableKey} = 'dateId';
    $definition->{sequenceKey} = '';

    $definition->{properties}{senderUserId} = {
            fieldType       => 'user',
            defaultValue    => undef,
        };
    $definition->{properties}{recipientUserId} = {
            fieldType       => 'user',
            defaultValue    => undef,
        };
    $definition->{properties}{dateType} = {
            fieldType       => 'text',
            defaultValue    => undef,
        };
    $definition->{properties}{subject} = {
            fieldType       => 'text',
            defaultValue    => undef,
        };
    $definition->{properties}{message} = {
            fieldType       => 'textArea',
            defaultValue    => undef,
        };
    $definition->{properties}{senderRemarks} = {
            fieldType       => 'textArea',
            defaultValue    => undef,
        };
    $definition->{properties}{recipientRemarks} = {
            fieldType       => 'textArea',
            defaultValue    => undef,
        };
    $definition->{properties}{recipientProperties} = {
            fieldType       => 'textArea',
            defaultValue    => undef,
        };
    $definition->{properties}{status} = {
            fieldType       => 'text',
            defaultValue    => undef,
        };
    $definition->{properties}{statusChanged} = {
            fieldType       => 'dateTime',
            defaultValue    => undef,
        };

    return $definition;
}

sub appendUserProfileVars {
    my $session = shift;
    my $var     = shift;
    my $user    = shift;
    my $prefix  = shift;

        my $privacySettingsHash = WebGUI::ProfileField->getPrivacyOptions($session);
        $var->{'profile_category_loop' } = [];
        foreach my $category (@{WebGUI::ProfileCategory->getCategories($session,{ visible => 1})}) {
            my @fields = ();
            foreach my $field (@{$category->getFields({ visible => 1 })}) {
                next unless ($user->canViewField($field->getId,$session->user));
                next if ($field->getId eq 'email');
		my $fieldId            = $field->getId;
		my $rawValue		= $user->profileField($fieldId);
                my $rawPrivacySetting  = $user->getProfileFieldPrivacySetting($field->getId);
                my $privacySetting     = $privacySettingsHash->{$rawPrivacySetting};
                my $fieldLabel         = $field->getLabel;
                my $fieldValue         = $field->formField(undef,2,$user,undef,$rawValue);
		my $fieldRaw           = $rawValue;
                # Create a seperate template var for each field
                my $fieldBase = $prefix.$fieldId;
                $var->{$fieldBase.'_label'                          } = $fieldLabel;
                $var->{$fieldBase.'_value'                          } = $fieldValue;
                $var->{$fieldBase.'_privacySetting'                 } = $privacySetting;
                $var->{$fieldBase.'_privacy_is_'.$rawPrivacySetting } = "true";
		$var->{$fieldBase.'_raw'                            } = $fieldRaw;
            }
        }
    return $var;
}


1;
