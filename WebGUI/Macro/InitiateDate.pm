package WebGUI::Macro::InitiateDate;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use lib "/data/customLib_WebGUI";

use strict;
use WebGUI::User;
use WebGUI::Dating::Date;

=head1 NAME

Package WebGUI::Macro::InitiateDate

=head1 DESCRIPTION

This macro initates a date by sending an email and adding the date to the database

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=item mailTemplateUrl

A templateUrl for the mail that this macro sends

=item from

The email address that is used as the 'from' and 'replyTo' properties of the email that this Macro sends

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session         = shift;
	my $templateUrl     = shift;
    my $mailTemplateUrl = shift;
    my $from            = shift;
    my $form            = $session->form;
    my $recipientUserId = $form->process('recipientUserId');
    my (%var,$var);

    return 'This macro requires a template url' unless($templateUrl);

    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    return 'U kunt geen date met uzelf aangaan.' if ($recipientUserId eq $session->user->userId);

    my $senderUserId = $session->user->userId;
    my $datesWithRecipient  = WebGUI::Dating::Date->getAllIds($session,{constraints => [
             {"((recipientUserId=? AND senderUserId=?) OR (senderUserId=? AND recipientUserId=?))" => 
                [$recipientUserId,$senderUserId,$recipientUserId,$senderUserId]},
        ]});
    if(scalar @$datesWithRecipient){
        $var{dateWithRecipientExists} = 1;
        my $date    = WebGUI::Dating::Date->new($session,$datesWithRecipient->[0]);
        my $status  = $date->get('status');
        $var{'is'.$status} = '1';
        if($date->get('senderUserId') eq $session->user->userId){
            $var{currentUserIsSender} = 1;
        }
    }
    elsif($form->process('sendEmail')){
        my $subject     = $form->process('subject');
        my $message     = $form->process('message');
        $var{message}   = $message;

        return 'This macro requires a recipientUserId' unless($recipientUserId);
        my $recipient = WebGUI::User->new($session,$recipientUserId);
        return 'Recipient does not exist' unless($recipient);

        return 'This macro requires a mail template url' unless($mailTemplateUrl);
        my $template = WebGUI::Asset::Template->newByUrl($session,$mailTemplateUrl);
        return 'Invalid mail template url' unless ($template);

        my ($recipientProperties,@recipientProperties,$dateType);
        
        foreach ($form->param) {
            if($_ =~ m/^recipientProperty_/){
                push(@recipientProperties,$form->param($_));
            }
        }
        if (scalar @recipientProperties > 0){
            $recipientProperties = join(', ',@recipientProperties);
            $var{recipientProperties} = $recipientProperties;
        }
        $dateType   = $form->process('direct') ? 'direct'
                    : 'introduction';
        
    
        # Add Date to database
        my $date = WebGUI::Dating::Date->create($session, {
                    subject             => $subject,
                    message             => $message,
                    recipientUserId     => $recipientUserId,
                    senderUserId        => $senderUserId,
                    status              => 'mailSent',
                    statusChanged       => WebGUI::DateTime->new($session,time())->toDatabase,
                    recipientProperties => $recipientProperties,
                    dateType            => $dateType
                });
        $var{dateId} = $date->getId;
    
        my $mailMessage = $template->process(\%var);
        
        # Send email
        my $mail = WebGUI::Mail::Send->create($session,{
            to      => $recipient->profileField('email'),
            replyTo => $from,
            subject => $form->process('subject'),
            from    => $from,
        });
        $mail->addHtml($mailMessage);
        $mail->addFooter;
        $mail->queue;

        $var{emailSent}         = 1;
        $var{recipientUserId}   = $recipientUserId;
        $var = \%var;
    }
    else{
        my $recipient = WebGUI::User->new($session,$recipientUserId);
        return 'Recipient does not exist' unless($recipient);
        
        $var{recipientFirstName}        = $recipient->profileField('firstName');
        $var{recipientMiddleName}       = $recipient->profileField('middleName');
        $var{recipientLastName}         = $recipient->profileField('lastName');
        $var{recipientPropertyPrefix}   = 'recipientProperty_';
        $var{subjectFormName}           = 'subject';
        $var{messageFormName}           = 'message';
        $var{submitFormName}            = 'sendEmail';
    
        $var = \%var;
        $var    = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$recipient,'recipient_');
    }

    return $template->process(\%var);	
}

1;

#vim:ft=perl
