package WebGUI::Macro::checkFormValue;

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
## This macro is Copyright 2007-2009 United Knowledge
## http://www.unitedknowledge.nl/
## Authors: Arjan Widlak, Yung Han Khoe
## Version: 0.1
## Date: 28th of August 2007
## Version: 0.2
## Date: 1st of July 2009
## Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
##-------------------------------------------------------------------
#

use strict;
use WebGUI::Macro;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Macro::checkFormValue;

=head1 DESCRIPTION

Macro that checks whether a form param has a certain value. 

#-------------------------------------------------------------------

=head2 process ( paramName, value, returnValueTrue, returnValueFalse )

Checks the value of a form param and returns a string.
This can be handy to check for example radiobuttons when a form is submitted but 
incomplete. Form elements like checkboxes that can have multiple values are supported. 
The macro is intended for list-type form elements but also works with 
other form elements like text inputs.

=head3 paramName

The name of the form param to check.

=head3 requiredValue

The value to check for.

=head3 returnValueTrue

The string to return if the required value is found.

=head3 returnValueFalse

The string to return if the required value is not found.

=cut

sub process {
	my $session             = shift;
	my $paramName           = shift;
	my $requiredValue       = shift;
	my $returnValueTrue     = shift;
    my $returnValueFalse    = shift;
	
	my @formValues = $session->form->process($paramName,'list');

    if (isIn($requiredValue,@formValues)) {
        return $returnValueTrue;
	}
    else{
		return $returnValueFalse;
	}
}

1;
