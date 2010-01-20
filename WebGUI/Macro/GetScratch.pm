package WebGUI::Macro::GetScratch;

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
use WebGUI::Session::Scratch;

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my $scratchName = shift;
	my $scratch = WebGUI::Session::Scratch->new($session);
	my $value = $scratch->get($scratchName);
	return $value;
}
#-------------------------------------------------------------------

1;
