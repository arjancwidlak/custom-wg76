package WebGUI::Macro::PersonalNewsLetter; 

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Asset;
use WebGUI::Group;
use WebGUI::User;
use WebGUI::Operation::Group;
use WebGUI::Form;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Mail::Send;
use WebGUI::Utility;
use WebGUI::Session::Url;
use HTML::Entities;

=head1 NAME
                                                                                                                                                             
Package WebGUI::Macro::PersonalNewsLetter;
                                                                                                                                                             
=head1 DESCRIPTION
                                                                                                                                                             
Macro that can send it's child assets to users in a specific group, generated for each user as they would view it. 
                                                                                                                                                             
=head2 process ( toGroupId , styleTemplateId , workflowId , useBcc)
                                                                                                                                                             
=head3 groupId
                                                                                                                                                             
The name of the group to send the email to. The group must exist.
                                                                                                                                                             
=head3 template
                                                                                                                                                             
The styleTemplate for the newsletter email.


=head3 workflowId


The ID of the workflow that sends the newsletters


=head3 useBcc


Send to recipient using bcc instead of to.                                                                                                                                                             

=cut

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my ($toGroupId,$styleTemplateId,$workflowId,$useBcc) = @_;

	if ($toGroupId eq ""){
		$session->errorHandler->error("The NewsLetter Macro needs a groupId of the group to send email to.");
		return "";
	}
	my $toGroup = WebGUI::Group->new($session,$toGroupId);	
	return $session->privilege->adminOnly() unless ($session->user->isInGroup(3) || ($toGroup->userIsAdmin) && $session->user->isInGroup(11));

	my $mFunc = $session->form->param("mFunc");
	my $output;
	if ($mFunc eq "emailGroupSend" && $session->form->param("assetUrl")){
		$output = www_emailGroupSend($session,$toGroupId,$styleTemplateId,$workflowId,$useBcc);
	}
    elsif($mFunc eq "emailTestSend" && $session->form->param("assetUrl")){	
		$output = www_emailTestSend($session,$toGroupId,$styleTemplateId,$workflowId,$useBcc);		
	}
    elsif($mFunc eq "emailGroup"){
                $output = www_emailGroup($session,$toGroupId,$styleTemplateId);
    }
    elsif($mFunc eq "emailTest"){
                $output = www_emailTest($session,$styleTemplateId);
    }
    else{
		$output = www_view($session,$toGroupId,$styleTemplateId,$workflowId,'',$useBcc);
	}
	return $output;
}

sub www_emailGroup {
    my $session         = shift;
	my $toGroupId       = shift;
	my $styleTemplateId = shift;
    my ($output,$f);

    my $i18nWebGUI  = WebGUI::International->new($session);
    my $i18n        = WebGUI::International->new($session,'Macro_PersonalNewsLetter');
    my $toGroup     = WebGUI::Group->new($session,$toGroupId); 

	$output .= "Weet u zeker dat u de nieuwbrief wilt versturen aan alle abonnees?<br><br>";
	
	$f = WebGUI::HTMLForm->new($session,{extras=>'"name"="myForm"'});
        $f->hidden(
                -name => "mFunc",
                -value => "emailGroupSend"
        );
        $f->hidden(
	        -name => "assetUrl",
		-value => $session->form->param("assetUrl"),
	);
	if ($session->user->isInGroup(3)){
	$f->email(
	        -name=>"from",
                -value=>$session->setting->get("companyEmail"),
                -label=>$i18nWebGUI->get(811),
                -hoverHelp=>$i18nWebGUI->get('811 description'),
                );
        }
	my $assetUrl = $session->form->param("assetUrl");
        my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
	$f->text(
                -name=>"subject",
		        -value=>$asset->get("title"),
                -label=>$i18nWebGUI->get(229),
                -hoverHelp=>$i18nWebGUI->get('229 description'),
                );
    my $startTime = time() + 120;	
    $f->dateTime(
                -name           =>"startTime",
		-value          =>$startTime,
                -label          =>$i18n->get('startTime label'),
                -hoverHelp      =>$i18n->get('startTime description'),
                );
    $f->integer(
                -name           =>"timeBetweenNewsLetters",
                -defaultValue   =>'1',
                -label          =>$i18n->get('timeBetweenNewsLetters label'),
                -hoverHelp      =>$i18n->get('timeBetweenNewsLetters description'),
                );
	$f->button(
                -value=>$i18nWebGUI->get('cancel'),
                -extras=>q|onclick="history.go(-1);"|
                );
    $f->submit(
        		-value=>"Verstuur",
	);

	$output .= $f->print();

    return $output;
}
                                                                                                                                                             
sub www_emailGroupSend {
    my $session         = shift;
	my $toGroupId       = shift;
	my $styleTemplateId = shift;
    my $workflowId      = shift;
    my $useBcc          = shift;
    my $db              = $session->db;
    my $form            = $session->form;
    my $toGroup         = WebGUI::Group->new($session,$toGroupId);
    my $assetUrl        = $form->process("assetUrl");
    my $asset           = WebGUI::Asset->newByUrl($session,$assetUrl);
    my $subject         = $form->process("subject") || $asset->get('title');
	my $from            = $form->process("from") || $session->setting->get("companyEmail");

    my $startTime               = $session->datetime->setToEpoch($form->process('startTime')) || time();
    my $timeBetweenNewsLetters  = $form->process('timeBetweenNewsLetters') || 1;

    foreach my $userId (@{$toGroup->getAllUsers}){
        my $to;
        my $user = WebGUI::User->new($session,$userId);
        next unless $user->profileField('email');
        if($useBcc){
                $to = $session->setting->get("companyEmail");
        }
        else{
            $to              = $user->profileField('email');
        }
        $session->errorHandler->info("adding newsletter for: ".$userId.", ".$user->profileField('email'));
        $db->write("insert into personalNewsLetterQueue (userId,assetUrl,styleTemplateId,`to`,subject,`from`,bcc) values
                    (?,?,?,?,?,?,?)"
                    ,[$userId,$assetUrl,$styleTemplateId,$to,$subject,$from,$user->profileField('email')]);
    }
    if ($workflowId){
        WebGUI::Workflow::Instance->create($session, {
            workflowId=>$workflowId,
            parameters=>[$startTime,$assetUrl,$timeBetweenNewsLetters]
        })->start(1);
    }
	$db->write("insert into Newsletter_sent (assetId, dateSent, sentBy, toGroupId, assetUrl) values (".$session->db->quote($asset->getId).", ".$session->datetime->time().", ".$session->db->quote($session->user->userId()).",".$session->db->quote($toGroupId).",".$session->db->quote($assetUrl).")");
	my $message =  "<br>De nieuwsbrief is verstuurd<br><br>";
    my $output = www_view($session,$toGroupId,$styleTemplateId,$workflowId,$message);
	return $output;
}

sub www_emailTest {
	my $session         = shift;
    my $styleTemplateId = shift;
    my ($output,$f);

    my $i18nWebGUI  = WebGUI::International->new($session);
    my $i18n        = WebGUI::International->new($session,'Macro_PersonalNewsLetter');

    $output .= "Weet u zeker dat u een test-nieuwbrief wilt versturen?<br><br>";

	$f = WebGUI::HTMLForm->new($session);
	$f->hidden(
                -name => "mFunc",
                -value => "emailTestSend"
        );
	$f->hidden(
                -name => "assetUrl",
                -value => $session->form->param("assetUrl"),
        );
    if ($session->user->isInGroup(3)){
        $f->email(
                -name=>"from",
                -value=>$session->setting->get("companyEmail"),
                -label=>$i18nWebGUI->get(811),
	        -hoverHelp=>$i18nWebGUI->get('811 description'),
	    );										
	}
    $f->user(
                -name=>"testUserId",
                -label=>"Aan",
    );
	my $assetUrl = $session->form->param("assetUrl");
        my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
        $f->text(
                -name=>"subject",
                -value=>$asset->get("title"),
                -label=>$i18nWebGUI->get(229),
              	-hoverHelp=>$i18nWebGUI->get('229 description'),
		);
	$f->email(
                -name=>"from",
                -value=>$session->setting->get("companyEmail"),
                -label=>$i18nWebGUI->get(811),
                -hoverHelp=>$i18nWebGUI->get('811 description'),
                );
	my $startTime = time() + 120;
	$f->dateTime(
                -name           =>"startTime",
		-value		=>$startTime,
                -label          =>$i18n->get('startTime label'),
                -hoverHelp      =>$i18n->get('startTime description'),
                );
    	$f->integer(
                -name           =>"timeBetweenNewsLetters",
                -defaultValue   =>'1',
                -label          =>$i18n->get('timeBetweenNewsLetters label'),
                -hoverHelp      =>$i18n->get('timeBetweenNewsLetters description'),
                );
	$f->button(
                -value=>$i18nWebGUI->get('cancel'),
                -extras=>q|onclick="history.go(-1);"|
                );
        $f->submit(
                -value=>"Verstuur",
                );

	$output .= $f->print();

	return $output;

}

sub www_emailTestSend {

    my $session         = shift;
    my $db		= $session->db;	
    my $toGroupId       = shift;
    my $styleTemplateId = shift;
    my $workflowId      = shift;
    my $useBcc          = shift;
    my $form            = $session->form;
    my $userId      	= $form->process('testUserId');
    my $user        	= WebGUI::User->new($session,$userId);
    my $to;
    if($useBcc){
        $to             = $session->setting->get("companyEmail");
    }
    else{
        $to             = $user->profileField('email');
    }
    my $startTime               = $session->datetime->setToEpoch($form->process('startTime')) || time();	
    my $timeBetweenNewsLetters  = $session->form->process("timeBetweenNewsLetters");	
    my $assetUrl        	= $session->form->process("assetUrl");
    my $asset           	= WebGUI::Asset->newByUrl($session,$assetUrl);
    my $subject         	= $session->form->process("subject") || $asset->get('title');
    my $from            	= $form->process("from") || $session->setting->get("companyEmail");	

        $session->errorHandler->info("adding newsletter for: ".$userId.", ".$user->profileField('email'));
        $db->write("insert into personalNewsLetterQueue (userId,assetUrl,styleTemplateId,`to`,subject,`from`,bcc) values
                    (?,?,?,?,?,?,?)"
                    ,[$userId,$assetUrl,$styleTemplateId,$to,$subject,$from,$user->profileField('email')]);
    
    if ($workflowId){
        WebGUI::Workflow::Instance->create($session, {
            workflowId=>$workflowId,
            parameters=>[$startTime,$assetUrl,$timeBetweenNewsLetters]
        })->start(1);
    }	
	
	my $message =  "<br>De test nieuwsbrief is verstuurd aan: ".$to."<br><br>";
        my $output = www_view($session,$toGroupId,$styleTemplateId,$workflowId,$message);
        return $output;
	
}

sub www_view {
	my $session         = shift;
	my $toGroupId       = shift;
	my $styleTemplateId = shift;
    my $workflowId      = shift;
	my $message         = shift;
    my $useBcc          = shift;
    my $db              = $session->db;
	
    my ($output,$f);
    my $i18n                = WebGUI::International->new($session,'Macro_PersonalNewsLetter');
    my $toGroup             = WebGUI::Group->new($session,$toGroupId);
    my $toGroupName         = $toGroup->get("groupName");
    my $styleTemplate       = WebGUI::Asset::Template->new($session,$styleTemplateId);
    my $styleTemplateName   = $styleTemplate->get("title");
    my $workflowTitle       = WebGUI::Workflow->new($session,$workflowId)->get('title');

	$output .= $message if ($message);

	if ($session->user->isInGroup(3)){
		$output .= "<br>toGroupId: ".$toGroupId."<br>";
		$output .= "toGroup name: ".$toGroupName."<br>";
		$output .= "styleTemplateId: ".$styleTemplateId."<br>";
		$output .= "styleTemplateName: ".$styleTemplateName."<br>";
        $output .= "workflowTitle: ".$workflowTitle."<br><br>";
        if($useBcc){
            $output .= "Newsletter will be sent using bcc field.<br>";
        }
	}

	my $page = WebGUI::Asset->newByUrl($session);
	my $children = $page->getLineage( ["children"], { returnObjects=>1, includeOnlyClasses=>["WebGUI::Asset::Wobject::Layout"] });
	
	$output .= "Nieuwsbrieven:<br>";
	foreach my $child (@$children){
        my $childUrl = $child->getUrl;
		my ($dateSent) = $db->quickArray("select max(dateSent) from Newsletter_sent where assetId = ".$db->quote($child->getId()));
		$output .= "<a href='".$childUrl."'>".$child->get("title")."</a>&nbsp;&nbsp;<a href='".$child->getUrl()."?op=makePrintable;styleId=".$styleTemplateId."' target='_blank'>[Bekijk email]</a>&nbsp;";
		$output .= "<a href='?mFunc=emailGroup;assetUrl=".$childUrl."'>[Verstuur]</a>&nbsp;";
		$output .= "<a href='?mFunc=emailTest;assetUrl=".$childUrl."'>[Verstuur test]</a><br>";
		if ($dateSent){
            $dateSent = $session->datetime->epochToHuman($dateSent);
            my $workflow = WebGUI::Workflow->new($session,$workflowId);
            my $workflowInstances = $workflow->getInstances;
            my (@parameters,$assetUrl);
            if(scalar @{$workflowInstances}){
                @parameters = @{$workflowInstances->[0]->get('parameters')};
                $assetUrl = $parameters[1];
            }
            if(scalar @{$workflowInstances} && ($assetUrl eq $childUrl)){
                my $currentActivityId = $workflowInstances->[0]->get('currentActivityId');
                #$session->errorHandler->info($workflowInstances->[0]);
                my $nextActivityName = $workflow->getNextActivity($currentActivityId)->getName;
                my $queueCount      = $db->quickScalar("select count(*) from personalNewsLetterQueue where assetUrl=?",
                                                    [$childUrl]) || '0';
                my $mailQueueCount  = $db->quickScalar("select count(*) from mailQueue") || '0';

                $output .= $i18n->get('sending in progress message').$dateSent.".<br />";
                $output .= $i18n->get('activity in progress message').$nextActivityName.".<br />" if $nextActivityName;
                $output .= $queueCount.$i18n->get('in queue message')."<br />";
                $output .= $mailQueueCount.$i18n->get('in mailQueue message')."<br />";
                $output .= "<a href='".$session->url->page()."'>Ververs</a><br /><br />";
            }
            else{
                $output .= "Verstuurd op ".$dateSent.".<br><br>";
            }
		}else{
		    $output .= "Nog niet verstuurd.<br><br>";
		}
	}
																			
	return $output;

}


sub getEmailContent {

	my $session         = shift;
    my $styleTemplateId = shift;
    my $testUserId      = shift;
    my $assetUrl        = shift;
    my $currentUserId   = $session->user->userId;
	
    
    $session->user({userId=>$testUserId});
	my $adminWasOn = $session->var->isAdminOn;
	#my $debugWasOn = $session->setting->get("showDebug");
	$session->var->switchAdminOff if $adminWasOn;
	#$session->setting->set("showDebug",0) if $debugWasOn;
    my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
    my $originalAsset = $session->asset;
	$session->asset($asset);
	my $html =  $session->style->process($asset->www_ajaxInlineView,$styleTemplateId);
	$session->asset($originalAsset);
	$session->var->switchAdminOn if $adminWasOn;
    $session->user({userId=>$currentUserId});
	#$session->setting->set("showDebug",1) if $debugWasOn;
	
 	$html = WebGUI::HTML::filter($html,"javascript");
	my $url = WebGUI::Session::Url->new($session);
	my $siteUrl = $url->getSiteURL;	
	$html = WebGUI::HTML::makeAbsolute($session,$html,$siteUrl);
	
	my $text = $html;
	#HTML::Entities::decode($text);
	$text =~ s/<a.*?href=["'](.*?)['"].*?>(.+?)<\/a>/$2 ($1)/g;
	$text = WebGUI::HTML::html2text($text);

        #my $htmlAbsolute = WebGUI::HTML::makeAbsolute($session,$html,$siteUrl);
	#$htmlAbsolute =~ s/a href=(["'])$siteUrl\/?#(.*?)(["'])/a href=$1#$2$3/g;
	
	return ($html, $text);

}


1;


