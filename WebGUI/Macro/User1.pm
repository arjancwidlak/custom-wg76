package WebGUI::Macro::User1;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2004 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Macro;
use WebGUI::Session;
use WebGUI::User;

sub process {
	my $session = shift;
	my $uid = shift;
	my $property = shift;
	my $user = WebGUI::User->new($session,$uid);
	#my $user = WebGUI::User->new($session,$session->form->process("uid"));
	return $user->profileField($property);
}

1;
