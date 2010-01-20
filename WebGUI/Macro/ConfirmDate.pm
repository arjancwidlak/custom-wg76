package WebGUI::Macro::ConfirmDate;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use lib '/data/customLib_WebGUI-7.4.40';

use strict;
use WebGUI::User;
use WebGUI::Dating::Date;

=head1 NAME

Package WebGUI::Macro::ConfirmDate

=head1 DESCRIPTION

This macro lets the recipient confirm or deny a date

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session         = shift;
	my $templateUrl     = shift;
	my $mailTemplateUrl = shift;
	my $from            = shift;
	my $subject         = shift;
    my $form            = $session->form;
    my $var;
	
    return 'This macro requires a template url' unless($templateUrl);
        
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    my $dateId = $form->process('dateId');
    return '' unless ($dateId);        

	my $date    = WebGUI::Dating::Date->new($session,$dateId);
    my $sender  = WebGUI::User->new($session,$date->get('senderUserId'));

    return '' unless ($date->get('recipientUserId') eq $session->user->userId);

    if($form->process('confirmDate')){
        $date->update({status=>'dateConfirmed',statusChanged=>WebGUI::DateTime->new($session, time())->toDatabase});
	$var 		= $date->get;
	$var 		= WebGUI::Dating::Date::appendUserProfileVars($session,$var,$sender,'mailTo_user_');
	my $recipient  	= WebGUI::User->new($session,$date->get('recipientUserId'));
	$var 		= WebGUI::Dating::Date::appendUserProfileVars($session,$var,$recipient,'confirmedBy_user_');

	# send email
	return 'This macro requires a mail template url' unless($mailTemplateUrl);
        my $template = WebGUI::Asset::Template->newByUrl($session,$mailTemplateUrl);
        return 'Invalid mail template url' unless ($template);

	my $mailMessage = $template->process($var);
	my $mail = WebGUI::Mail::Send->create($session,{
            to      => $sender->profileField('email'),
            replyTo => $from,
            subject => $subject,
            from    => $from,
        });
        $mail->addHtml($mailMessage);
        $mail->addFooter;
        $mail->queue;

        $var->{sender_email_value} = $sender->profileField('email');	
	$var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$sender,'sender_');
    }
    elsif($form->process('denyDate')){
	$var = $date->get;
        $var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$sender,'sender_');
        $date->update({status=>'dateDenied',statusChanged=>WebGUI::DateTime->new($session, time())->toDatabase});
	$var->{dateDenied} = 1;
    }
    else{
        $date->update({status=>'dateViewed',statusChanged=>WebGUI::DateTime->new($session, time())->toDatabase});
        $var = $date->get;
	$var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$sender,'sender_');
    }
    
   return $template->process($var);
}

sub appendSenderProfileVars {
    my $session = shift;
    my $var     = shift;
    my $sender  = shift;

        my $privacySettingsHash = WebGUI::ProfileField->getPrivacyOptions($session);
        $var->{'profile_category_loop' } = [];
        foreach my $category (@{WebGUI::ProfileCategory->getCategories($session,{ visible => 1})}) {
            my @fields = ();
            foreach my $field (@{$category->getFields({ visible => 1 })}) {
                next unless ($sender->canViewField($field->getId,$session->user));
                next if ($field->getId eq 'email');
                my $rawPrivacySetting  = $sender->getProfileFieldPrivacySetting($field->getId);
                my $privacySetting     = $privacySettingsHash->{$rawPrivacySetting};
                my $fieldId            = $field->getId;
                my $fieldLabel         = $field->getLabel;
                my $fieldValue         = $field->formField(undef,2,$sender);
                my $fieldRaw           = $sender->profileField($fieldId);
                # Create a seperate template var for each field
                my $fieldBase = 'sender_'.$fieldId;
                $var->{$fieldBase.'_label'                          } = $fieldLabel;
                $var->{$fieldBase.'_value'                          } = $fieldValue;
                $var->{$fieldBase.'_raw'                            } = $fieldRaw;
                $var->{$fieldBase.'_privacySetting'                 } = $privacySetting;
                $var->{$fieldBase.'_privacy_is_'.$rawPrivacySetting } = "true";
            }
        }
    return $var;
}

1;

#vim:ft=perl
