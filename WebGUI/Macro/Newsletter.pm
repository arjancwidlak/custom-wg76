package WebGUI::Macro::Newsletter; 

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
#use Tie::CPHash;
#use WebGUI::AdminConsole;
use WebGUI::Asset;
use WebGUI::Group;
use WebGUI::Operation::Group;
use WebGUI::Form;
use WebGUI::HTMLForm;
use WebGUI::International;
use WebGUI::Mail::Send;
#use WebGUI::Operation::User;
#use WebGUI::Paginator;
#use WebGUI::SQL;
use WebGUI::Utility;
use WebGUI::Session::Url;
use HTML::Entities;

=head1 NAME
                                                                                                                                                             
Package WebGUI::Macro::Newsletter;
                                                                                                                                                             
=head1 DESCRIPTION
                                                                                                                                                             
Macro that allows admins and secondary admins to email an asset to a group.
                                                                                                                                                             
=head2 process ( toGroupId, , styleTemplateId )
                                                                                                                                                             
=head3 groupId
                                                                                                                                                             
The name of the group to send the email to. The group must exist.
                                                                                                                                                             
=head3 ?
                                                                                                                                                             
                                                                                                                                                             
=head3 template
                                                                                                                                                             
The template for www_emailGroup.
                                                                                                                                                             
=cut

#-------------------------------------------------------------------
sub process {
	#my @param = @_;
	my $session = shift;
	my ($toGroupId,$styleTemplateId) = @_;
	if ($toGroupId eq ""){
		$session->errorHandler->error("The NewsLetter Macro needs a groupId of the group to send email to.");
		return "";
	}
	my $toGroup = WebGUI::Group->new($session,$toGroupId);	
	return $session->privilege->adminOnly() unless ($session->user->isInGroup(3) || ($toGroup->userIsAdmin) && $session->user->isInGroup(11));
	my $mFunc = $session->form->param("mFunc");
	# my $somePassedInParameter = shift;
	# my $someOtherPassedInParameter = shift;
	my $output;
	if ($mFunc eq "emailGroupSend" && $session->form->param("assetUrl")){
		$output = www_emailGroupSend($session,$toGroupId,$styleTemplateId);
	}elsif($mFunc eq "emailTestSend" && $session->form->param("assetUrl")){	
		$output = www_emailTestSend($session,$toGroupId,$styleTemplateId);		
	}elsif($mFunc eq "emailGroup"){
                $output = www_emailGroup($session,$toGroupId,$styleTemplateId);
        }elsif($mFunc eq "emailTest"){
                $output = www_emailTest($session,$styleTemplateId);
        }else{
		$output = www_view($session,$toGroupId,$styleTemplateId);
	}
	return $output;
}

sub www_emailGroup {
        my $session = shift;
	my $toGroupId = shift;
	my $styleTemplateId = shift;
        my ($output,$f);
        my $i18n = WebGUI::International->new($session);
        my $toGroup = WebGUI::Group->new($session,$toGroupId); 

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
                -label=>$i18n->get(811),
                -hoverHelp=>$i18n->get('811 description'),
                );
        }
	my $assetUrl = $session->form->param("assetUrl");
        my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
	$f->text(
                -name=>"subject",
		-value=>$asset->get("title"),
                -label=>$i18n->get(229),
                -hoverHelp=>$i18n->get('229 description'),
                );
	$f->button(
                -value=>$i18n->get('cancel'),
                -extras=>q|onclick="history.go(-1);"|
                );
        $f->submit(
		-value=>"Verstuur",
		);

	$output .= $f->print();

=cut	
	$output .= '
Preview html mail:<br>
<object data="http://wg-dev.nl:8080/home/test-newsletter/newsletter-macro?mFunc=getAssetHTML;assetUrl=home/test-newsletter/nieuwsbrief-1" width="100%" height="250" type="text/html">
</object>
';
=cut
        return $output;
}
                                                                                                                                                             
sub www_emailGroupSend {
        my $session = shift;
	my $toGroupId = shift;
	my $styleTemplateId = shift;
	
	my ($html,$text,$subject) = getEmailContent($session,$styleTemplateId);
	
	my $from = $session->form->process("from") || $session->setting->get("companyEmail");
        my $mail = WebGUI::Mail::Send->create($session, {toGroup=>$toGroupId,subject=>$subject,from=>$from,contentType=>"multipart/alternative"});
	
	#my $text = HTML::Entities::decode($html);
	
        $mail->{_message}->attach(
                Charset=>"ISO-8859-1",
                Data=>$text
                );

	$mail->addHtml($html);
        #$mail->addFooter;
        $mail->queue;
	my $assetUrl = $session->form->param("assetUrl");
        my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
	$session->db->write("insert into Newsletter_sent (assetId, dateSent, sentBy, toGroupId, assetUrl) values (".$session->db->quote($asset->getId).", ".$session->datetime->time().", ".$session->db->quote($session->user->userId()).",".$session->db->quote($toGroupId).",".$session->db->quote($assetUrl).")");
	my $message =  "<br>De nieuwsbrief is verstuurd<br><br>";
        my $output = www_view($session,$toGroupId,$styleTemplateId,$message);
	return $output;
}

sub www_emailTest {

	my $session = shift;
        my $styleTemplateId = shift;
        my ($output,$f);

	my $i18n = WebGUI::International->new($session);
        #my $toGroup = WebGUI::Group->new($session,$toGroupId);

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
                -label=>$i18n->get(811),
	        -hoverHelp=>$i18n->get('811 description'),
	);										
	}

	$f->email(
                -name=>"to",
                -label=>"Aan",
	);								       
	
	my $assetUrl = $session->form->param("assetUrl");
        my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
        $f->text(
                -name=>"subject",
                -value=>$asset->get("title"),
                -label=>$i18n->get(229),
              	-hoverHelp=>$i18n->get('229 description'),
		);
	$f->button(
                -value=>$i18n->get('cancel'),
                -extras=>q|onclick="history.go(-1);"|
                );
        $f->submit(
                -value=>"Verstuur",
                );

	$output .= $f->print();

	return $output;

}

sub www_emailTestSend {

	my $session = shift;
	my $toGroupId = shift;
        my $styleTemplateId = shift;
        my ($html,$text,$subject) = getEmailContent($session,$styleTemplateId);

        my $from = $session->form->process("from") || $session->setting->get("companyEmail");
        my $mail = WebGUI::Mail::Send->create($session, {to=>$session->form->process("to"),subject=>$subject,from=>$from,contentType=>"multipart/alternative"});

	$mail->{_message}->attach(
                Charset=>"ISO-8859-1",
                Data=>$text
                );

        $mail->addHtml($html);
        #$mail->addFooter;
        $mail->queue;

	my $message =  "<br>De test nieuwsbrief is verstuurd aan: ".$session->form->process("to")."<br><br>";
        my $output = www_view($session,$toGroupId,$styleTemplateId,$message);
        return $output;
	
}

sub www_view {
	my $session = shift;
	my $toGroupId = shift;
	my $styleTemplateId = shift;
	my $message = shift;
	
        my ($output,$f);
	#my $i18n = WebGUI::International->new($session);
        my $toGroup = WebGUI::Group->new($session,$toGroupId);
        my $toGroupName = $toGroup->get("groupName");
        my $styleTemplate = WebGUI::Asset::Template->new($session,$styleTemplateId);
        my $styleTemplateName = $styleTemplate->get("title");

	$output .= $message if ($message);

	if ($session->user->isInGroup(3)){
		$output .= "<br>toGroupId: ".$toGroupId."<br>";
		$output .= "toGroup name: ".$toGroupName."<br>";
		$output .= "styleTemplateId: ".$styleTemplateId."<br>";
		$output .= "styleTemplateName: ".$styleTemplateName."<br><br>";
	}

	my $page = WebGUI::Asset->newByUrl($session);
	my $children = $page->getLineage( ["children"], { returnObjects=>1, includeOnlyClasses=>["WebGUI::Asset::Wobject::Layout"] });
	
	$output .= "Nieuwsbrieven:<br>";
	foreach my $child (@$children){
		my ($dateSent) = $session->db->quickArray("select max(dateSent) from Newsletter_sent where assetId = ".$session->db->quote($child->getId()));
		$output .= "<a href='".$child->getUrl()."'>".$child->get("title")."</a>&nbsp;&nbsp;<a href='".$child->getUrl()."?op=makePrintable;styleId=".$styleTemplateId."' target='_blank'>[Bekijk email]</a>&nbsp;";
		$output .= "<a href='?mFunc=emailGroup;assetUrl=".$child->getUrl()."'>[Verstuur]</a>&nbsp;";
		$output .= "<a href='?mFunc=emailTest;assetUrl=".$child->getUrl()."'>[Verstuur test]</a><br>";
		if ($dateSent){
		$output .= "Verstuurd op ".$session->datetime->epochToHuman($dateSent).".<br><br>";
		}else{
		$output .= "Nog niet verstuurd.<br><br>";
		}
#		$f->submit(
#			-label=>$child->get("title"),
#			-value=>"Verstuur",
#			-extras=>"onClick='this.form.assetUrl.value=\"".$child->getUrl()."\";return confirm(\"Weet u zeker dat u de nieuwsbrief naar alle abonnees wilt versturen?\")'",
#			);
	}
																			
	return $output;

}


sub getEmailContent {

	my $session = shift;
        my $styleTemplateId = shift;
	
	my $adminWasOn = $session->var->isAdminOn;
	#my $debugWasOn = $session->setting->get("showDebug");
	$session->var->switchAdminOff if $adminWasOn;
	#$session->setting->set("showDebug",0) if $debugWasOn;
        my $assetUrl = $session->form->param("assetUrl");
        my $asset = WebGUI::Asset->newByUrl($session,$assetUrl);
	my $subject = $session->form->process("subject") || $asset->get("title");
        my $originalAsset = $session->asset;
	$session->asset($asset);
	my $html =  $session->style->process($asset->www_ajaxInlineView,$styleTemplateId);
	$session->asset($originalAsset);
	$session->var->switchAdminOn if $adminWasOn;
	#$session->setting->set("showDebug",1) if $debugWasOn;
	
 	$html = WebGUI::HTML::filter($html,"javascript");	
	
	my $text = $html;
	$text =~ s/<a.*?href=["'](.*?)['"].*?>(.+?)<\/a>/$2 ($1)/g;
	$text = WebGUI::HTML::html2text($text);

	my $url = WebGUI::Session::Url->new($session);
	my $siteUrl = $url->getSiteURL;
        my $htmlAbsolute = WebGUI::HTML::makeAbsolute($session,$html,$siteUrl);
	$htmlAbsolute =~ s/a href=(["'])$siteUrl\/?#(.*?)(["'])/a href=$1#$2$3/g;
	
	return ($htmlAbsolute, $text, $subject);

}


1;


