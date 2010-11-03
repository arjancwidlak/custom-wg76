package WebGUI::Macro::ProfileValidator;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::User;
use WebGUI::ProfileField;

=head1 NAME

Package WebGUI::Macro::ProfileValidator

=head1 DESCRIPTION

This macro shows other users dates with whom the current user does not have a date with yet, who are in the same 'sector' but in a different kind of 'organisation'. They are ordered by the number of dates they have.

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=item percentage

The number of registration fields that are not required as a percentage of the total number of registration fields.

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session     = shift;
	my $templateUrl = shift;
	my $percentage 	= shift;
    
    my $form            = $session->form;
    my $currentUserId   = $session->user->userId;
    my ($var,$date,$currentUserIsSender);
	
    return 'This macro requires a template url' unless($templateUrl);
        
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    $var->{editProfileUrl} = $session->url->page('op=account;module=profile');

    my @field_loop;
    my $registrationFields = 0;	
    #foreach my $field (@{WebGUI::ProfileField->getRegistrationFields($session)}) {
    foreach my $field (@{WebGUI::ProfileField->getEditableFields($session)}) {
	next if ($field->isRequired);
	$registrationFields++;
	next if ($field->formField(undef,2,$session->user));
	my $fieldName = $field->getId;
	push(@field_loop,{fieldLabel => $field->getLabel, fieldName => $fieldName});
	$var->{'isIncomplete_'.$fieldName} = 1;
    }   
    my $incompleteRegistrationFields = scalar @field_loop; 	
    my $percentageComplete = 
        ($percentage * (($registrationFields - $incompleteRegistrationFields)/$registrationFields))+(100 - $percentage);
    $var->{percentageComplete} = sprintf("%.0f",$percentageComplete);
    my $percentagePerField = $percentage/$registrationFields;	
    $var->{percentagePerField} = sprintf("%.2f",$percentagePerField);
    $var->{incompleteRegistrationFields} = $incompleteRegistrationFields;
    $var->{registrationFields} = $registrationFields; 	
    $var->{field_loop} = \@field_loop; 
   
    return $template->process($var);
}

1;

#vim:ft=perl
