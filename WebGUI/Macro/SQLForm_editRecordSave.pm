package WebGUI::Macro::SQLForm_editRecordSave;

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

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my $id = shift || "FR-A00DzCSZXmfA7SIri6g";
	my $someOtherPassedInParameter = shift;
	my $output = ""; # do some stuff
	my $SQLForm = WebGUI::Asset->new($session, $id, "WebGUI::Asset::Wobject::SQLForm");
	my $output = $SQLForm->www_ajaxInlineView();
	return "bla: ".$output;
}

1;


