package WebGUI::Macro::messageStatus;

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
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Macro::messageStatus;

=head1 DESCRIPTION

This macro checks the status of a message by its message_url. If the 
status is as requested the message will be displayed.

=head2 process ( message_url, status, message )

=head3 message_url

The message_url as recevied from <tmpl_var message_url> that can be 
used in the inbox template.

=head 3 status

A status to check the message with. This can be 'unread', 'pending', 
'read', 'replied' or 'completed'.

=head 3 message

A message that will be displayed if the status is equal to the status 
given to the macro.

=cut

#-------------------------------------------------------------------

sub process {
        my $session = shift;

	my $status = shift;
        my $messageUrl = shift;
	my $message = shift;
	
	my @urlparts = split(/=/, $messageUrl);
	my $messageId = pop(@urlparts);
	my ($messageStatus) = $session->db->quickArray("select status from inbox where messageid=".$session->db->quote($messageId));
	return $message if $messageStatus eq $status;
}
1;
