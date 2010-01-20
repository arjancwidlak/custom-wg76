package WebGUI::Macro::SiteName; 

#
###-------------------------------------------------------------------
### This macro is Copyright 2007 United Knowledge
### http://www.unitedknowledge.nl/
### Author: Arjan Widlak
### Version: 0.1
### Date: 19th of November 2007
### Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
###-------------------------------------------------------------------
##
#

use strict;

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my $sitename = $session->config->get("sitename")->[0];
	return $sitename;
}

1;


