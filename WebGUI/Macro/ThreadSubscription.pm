package WebGUI::Macro::ThreadSubscription;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2003 Plain Black LLC.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------
# This Macro was created by United Knowledge GoI.
# If you would like to use this Macro, please contact us.
# http://www.unitedknowledge.nl
# developmentinfo@unitedknowledge.nl
#-------------------------------------------------------------------

use strict;
#use WebGUI::Session;
#use WebGUI::SQL;
#use WebGUI::Grouping;
#use WebGUI::Cache;
use WebGUI::User;

#-------------------------------------------------------------------
sub process{
	my $session = shift;
	my ($username, $threadId, $parentId, $subscribeLabel, $unsubscribeLabel, $isSubscribedLabel, $isNotSubscribedLabel) = @_;
	
	my ($isSubscribed, $changeLabel, $statusLabel, $mFunc);
	
	my ($userId) = $session->db->quickArray("SELECT userId FROM users WHERE username = ".$session->db->quote($username));
	
	my ($subscriptionGroupId) = $session->db->quickArray("SELECT subscriptionGroupId FROM Thread WHERE assetId = ".$session->db->quote($threadId));
	
	my $user = WebGUI::User->new($session, $userId);
	$isSubscribed = $user->isInGroup($subscriptionGroupId);
	
	if ($session->form->param("mFunc") eq "deleteThreadSubscription" && $session->form->param("threadId") eq $threadId && $isSubscribed){
			
		#WebGUI::Cache->new("cspost_".$threadId."_".$userId."_".$session->scratch->get("discussionLayout")."_")->delete;
		#WebGUI::Cache->new("wobject_".$parentId."_".$session->user->userId())->delete;
		#WebGUI::Grouping::deleteUsersFromGroups([$userId],[$subscriptionGroupId]);
		my $group = WebGUI::Group->new($session,$subscriptionGroupId);
		$group->deleteUsers([$userId]);
		$isSubscribed = "";
		
	}elsif ($session->form->param("mFunc") eq "addThreadSubscription" && $session->form->param("threadId") eq $threadId && !$isSubscribed){
		
		#WebGUI::Cache->new("wobject_".$parentId."_".$session->user->userId())->delete;
		#WebGUI::Cache->new("cspost_".$threadId."_".$userId."_".$session->scratch->get("discussionLayout")."_")->delete;
		my $group = WebGUI::Group->new($session,$subscriptionGroupId);
                $group->addUsers([$userId]);
		#WebGUI::Grouping::addUsersToGroups([$userId],[$subscriptionGroupId]);
		$isSubscribed = 1;
	
	}
	if ($isSubscribed){
		$changeLabel = $unsubscribeLabel || "Unsubscribe";
		$statusLabel = $isSubscribedLabel || "Subscribed";
		$mFunc = "deleteThreadSubscription";
	}else{
		$changeLabel = $subscribeLabel || "Subscribe";
		$statusLabel = $isNotSubscribedLabel || "Not Subscribed";
		$mFunc = "addThreadSubscription";
	}	
	return $statusLabel." <a href='?mFunc=".$mFunc.";threadId=".$threadId.";pn=1'>$changeLabel</a>";
}
#-------------------------------------------------------------------

1;
