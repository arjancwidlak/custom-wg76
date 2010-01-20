package WebGUI::Macro::MyDates;

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
use WebGUI::Dating::Date;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Macro::Dates

=head1 DESCRIPTION

This macro shows the current users dates and provides some editing on those dates.

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=item mailTemplateUrl

A templateUrl for the mail that this macro sends

=item from

The email address that is used as the 'from' and 'replyTo' properties of the email that this Macro sends

=item maximumDates

The maximum number of dates that should be displayed, this parameter is optional. If it is not defined all dates
will be displayed.

=item deleteSubject

The subject of the email that is sent when a date is deleted.

=item includeStatuses

The statuses that should be included, optional.

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session         = shift;
	my $templateUrl     = shift;
    my $mailTemplateUrl = shift;
    my $from            = shift;
    my $deleteSubject   = shift || 'date deleted';
    my $maximumDates    = shift;
    my $includeStatuses = shift;	
    my $form            = $session->form;
    my $currentUserId   = $session->user->userId;
    my ($var,$date,$currentUserIsSender);
	
    return 'This macro requires a template url' unless($templateUrl);
        
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    $var->{url} = $session->url->page;

    if($form->process('dateId')){
        $date = WebGUI::Dating::Date->new($session,$form->process('dateId'));
        if($date->get('senderUserId') eq $currentUserId){
            $currentUserIsSender        = 1;
            $var->{currentUserIsSender} = 1;
        }
    }

    if($form->process('deleteDate') && $form->process('dateId')){

        return 'This macro requires a mail template url' unless($mailTemplateUrl);
        my $template = WebGUI::Asset::Template->newByUrl($session,$mailTemplateUrl);
        return 'Invalid mail template url' unless ($template);

        my $dateStatus = $date->get('status');
        if($currentUserIsSender){
            # current user is sender
            if(WebGUI::Utility::isIn($dateStatus,qw(deletedByRecipient dateDenied))){
                $date->delete; 
            }
            else{
                $date->update({ status          =>'deletedBySender',
                                statusChanged   =>WebGUI::DateTime->new($session,time())->toDatabase});
                # send email
                sendDeleteMail(
                    $session,$template,$from,$deleteSubject,$date->get('recipientUserId'),$date->get('senderUserId')
                );
            }
        }
        else{
            # current user is recipient
            if($dateStatus eq 'deletedBySender'){
                $date->delete;
            }
            else{
                $date->update({ status=>'deletedByRecipient',
                                statusChanged   =>WebGUI::DateTime->new($session,time())->toDatabase});
                # send email
                sendDeleteMail(
                    $session,$template,$from,$deleteSubject,$date->get('senderUserId'),$date->get('recipientUserId')
                );
            }
        }
    }
    elsif($form->process('editSaveDate') && $form->process('dateId')){
        if($currentUserIsSender){
            $date->update({senderRemarks=>$form->process('senderRemarks')});
        }
        else{
            $date->update({recipientRemarks=>$form->process('recipientRemarks')});
        }
    }
    elsif($form->process('editDate') && $form->process('dateId')){
        if($currentUserIsSender){
            my $otherUser = WebGUI::User->new($session,$date->get('recipientUserId'));
            $var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$otherUser,'other_user_');
            $var->{senderRemarks} = $date->get('senderRemarks');
        }
        else{
            my $otherUser = WebGUI::User->new($session,$date->get('senderUserId'));
            $var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$otherUser,'other_user_');
            $var->{recipientRemarks} = $date->get('recipientRemarks');
        }
    }
    
    
    my @date_loop;
    my $allIteratorConfig = {
            constraints =>  [
                            {"senderUserId=? or recipientUserId=?" => [$currentUserId,$currentUserId]},
                            ],
            orderBy     => 'dateCreated desc, status',
        };
    if($includeStatuses){
	$includeStatuses =~ s/\|/,/g;
	push(@{$allIteratorConfig->{constraints}},{"status in(?)" => [$includeStatuses]});
    }		
    if ($maximumDates){
        $allIteratorConfig->{limit} = $maximumDates
    }
    my $getADate = WebGUI::Dating::Date->getAllIterator($session,$allIteratorConfig);
    while (my $dateObject = $getADate->()) {
        my $date = $dateObject->get;

        $date->{dateCreated} = WebGUI::DateTime->new($session,$date->{dateCreated})->toUserTimeZone;
        $date->{lastUpdated} = WebGUI::DateTime->new($session,$date->{lastUpdated})->toUserTimeZone;

        if($date->{senderUserId} eq $currentUserId){
            #$currentUserIsSender        = 1;
            $date->{currentUserIsSender} = 1;
        }
        $date->{deleteDateUrl}  = $session->url->page('deleteDate=1;dateId='.$date->{dateId});
        $date->{editDateUrl}    = $session->url->page('editDate=1;dateId='.$date->{dateId});
        my $otherUser;
        if($date->{senderUserId} eq $currentUserId){
            # current user is sender
            next if($date->{status} eq 'deletedBySender');
            $otherUser = WebGUI::User->new($session,$date->{recipientUserId});
        }
        else{
            # current user is recipient
            next if($date->{status} eq 'deletedByRecipient');
            $otherUser = WebGUI::User->new($session,$date->{senderUserId});
        }
        $date = WebGUI::Dating::Date::appendUserProfileVars($session,$date,$otherUser,'other_user_');
        my $isStatusLabel       = 'is'.ucfirst $date->{status};
        $date->{$isStatusLabel} = 1;
	$date->{other_user_email_value} = $otherUser->profileField('email');
	$date->{other_user_userId} 	= $otherUser->userId;
	$date->{other_user_username} 	= $otherUser->username;
        push(@date_loop, $date);
    }   
    $var->{date_loop} = \@date_loop; 
   
    return $template->process($var);
}

sub sendDeleteMail{
    my $session     = shift;
    my $template    = shift;
    my $from        = shift;
    my $subject     = shift;
    my $mailToId    = shift;
    my $deletedById = shift;

    my $mailToUser      = WebGUI::User->new($session,$mailToId);
    my $deletedByUser   = WebGUI::User->new($session,$deletedById);
    my $var;
    $var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$mailToUser,'mailTo_user_');
    $var = WebGUI::Dating::Date::appendUserProfileVars($session,$var,$deletedByUser,'deletedBy_user_');
    my $mailMessage = $template->process($var);

    # Send email
    my $mail = WebGUI::Mail::Send->create($session,{
        to      => $mailToUser->profileField('email'),
        replyTo => $from,
        subject => $subject,
        from    => $from,
    });
    $mail->addHtml($mailMessage);
    $mail->addFooter;
    $mail->queue;
}

1;

#vim:ft=perl
