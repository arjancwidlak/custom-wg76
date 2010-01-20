package WebGUI::Macro::checkRadio;

#-------------------------------------------------------------------
## WebGUI is Copyright 2001-2005 Plain Black Corporation.
##-------------------------------------------------------------------
## Please read the legal notices (docs/legal.txt) and the license
## (docs/license.txt) that came with this distribution before using
## this software.
##-------------------------------------------------------------------
## http://www.plainblack.com                     info@plainblack.com
##-------------------------------------------------------------------
#
#
##-------------------------------------------------------------------
## This macro is Copyright 2007 United Knowledge
## http://www.unitedknowledge.nl/
## Author: Arjan Widlak
## Version: 0.1
## Date: 28th of August 2007
## Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
##-------------------------------------------------------------------
#

use strict;
use WebGUI::Macro;

=head1 NAME

Package WebGUI::Macro::checkRadio;

=head1 DESCRIPTION

Macro for displaying a users avatar, photo or other image. 

#-------------------------------------------------------------------

=head2 process ( fieldName, value, returnValue )

Checks the value of a processed form element and returns a string.
This can be handy to check radiobuttons when a form is submitted but 
incomplete.

=head3 fieldName



=head3 value


=head3 returnValue

=cut

sub process {
	my $session = shift;
	
	my $formName = shift;
	my $requiredValue = shift;
	my $formValue = $session->form->process($formName);
	my $returnValue = shift;
	
	
	if ($requiredValue eq $formValue) {
		return "$returnValue";
		
	}else{
		return "";
	}
}
1;
