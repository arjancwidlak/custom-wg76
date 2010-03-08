package WebGUI::Workflow::Activity::AddUserToGroup::DataFormEntry; 


=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use WebGUI::User;
use base 'WebGUI::Workflow::Activity';

=head1 NAME

Package WebGUI::Workflow::Activity::AddUserToGroup::DataFormEntry

=head1 DESCRIPTION

Add a user to a group, for use in a workflow triggered by DataForm

=cut


#-------------------------------------------------------------------

=head2 definition ( session, definition )

See WebGUI::Workflow::Activity::defintion() for details.

=cut 

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session, "Workflow_Activity_AddUserToGroup_DataFormEntry");
	push(@{$definition}, {
		name=>$i18n->get("activityName"),
		properties=> {
			groupId => {
				fieldType=>"group",
				label=>"Some Field",
				defaultValue=>undef,
				excludeGroups=>[7,2,1],
				hoverHelp=>$i18n->get("group help")
				},
			expireOffset => {
				fieldType=>"interval",
				label=>$i18n->get("expire offset"),
				defaultValue=>60*60*24*365,
				hoverHelp=>$i18n->get("expire offset help")
				},
			}
		});
	return $class->SUPER::definition($session,$definition);
}


#-------------------------------------------------------------------

=head2 execute ( [ object ] )

See WebGUI::Workflow::Activity::execute() for details.

=cut

sub execute {
	my $self = shift;
    my $user = WebGUI::User->new($self->session,$self->session->user->userId);
	$user->addToGroups([$self->get("groupId")], $self->get("expireOffset"));
    return $self->COMPLETE;
}



1;

#vim:ft=perl
