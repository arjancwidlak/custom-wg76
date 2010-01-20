package WebGUI::Macro::Ecard;

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

=head1 NAME

Package WebGUI::Macro::Ecard;

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

   my $session = shift;
   if($session->form->process("userDefined2") && ($session->form->process("func") eq "editSave")){
        my ($templateId) = @_;
	my %var;
	my $to = $session->form->process("userDefined2");
	($var{'ecard.url'},$var{'ecard.assetId'}) =  $session->db->quickArray("select url, assetData.assetId from assetData left join Post using(assetId) where userDefined1 = '".$session->form->process("userDefined1")."' and userDefined2 = '".$session->form->process("userDefined2")."' and userDefined3 = '".$session->form->process("userDefined3")."' and userDefined4 = '".$session->form->process("userDefined4")."' and content = '".$session->form->process("content")."' order by assetData.revisionDate desc limit 1");
        $var{'ecard.toEmail'} = $to;
	my $html =  WebGUI::Asset::Template->new($session,$templateId)->process(\%var);	
	
	my $subject = "E-card van ".$session->form->process("userDefined3");
	#my $text = "bla";

=cut
	if ($session->form->process("bevestiging1")){
		$bcc = $session->form->process("userDefined4");
	}
=cut
        my $from = $session->form->process("from") || $session->setting->get("companyEmail");
        my $mail = WebGUI::Mail::Send->create($session, {to=>$to,subject=>$subject,from=>$from,contentType=>"multipart/alternative"});
=cut
        $mail->{_message}->attach(
                Charset=>"ISO-8859-1",
                Data=>$text
                );

=cut
        $mail->addHtml($html);
        $mail->queue;
	if ($session->form->process("bevestiging1")){
		$to = $session->form->process("userDefined4");
		$mail = WebGUI::Mail::Send->create($session, {to=>$to,subject=>"Kopie e-card",from=>$from,contentType=>"multipart/alternative"});
		$var{'ecard.toEmail'} = $to;
		$html =  WebGUI::Asset::Template->new($session,$templateId)->process(\%var);
		$mail->addHtml($html);
		$mail->queue;
	}
	return "De e-card is verzonden.";
   }elsif($session->form->process("ecardId")){
	my ($bericht,$ontvanger_naam,$ontvanger_email,$afzender_naam,$afzender_email,$bevestiging) =  $session->db->quickArray("select content, userDefined1,userDefined2,userDefined3, userDefined4, userDefined5 from Post where assetId = '".$session->form->process("ecardId")."' order by revisionDate desc limit 1");
	
	if ($bevestiging eq "bevestig_bezorging" && ($session->form->process("email") eq $ontvanger_email)){	
	        my $from = $session->form->process("from") || $session->setting->get("companyEmail");
		my $mail = WebGUI::Mail::Send->create($session, {to=>$afzender_email,subject=>"Ontvangstbevestiging e-card",from=>$from,contentType=>"multipart/mixed"});
		$mail->addText("Beste ".$afzender_naam.",\n\n".$ontvanger_naam." heeft je e-card opgehaald.\n\nJe hebt bij het versturen gevraagd om een ontvangstbevestiging,om die reden sturen we je dit bericht.");
	        $mail->queue;	
	
		$session->db->write("update Post set userDefined5 = 'bezorging_bevestigd' where assetId = '".$session->form->process("ecardId")."'");
	}
	return "Bericht: ".$bericht."<br /><br />Van: ".$afzender_naam;
   }

}

1;
