package WebGUI::Macro::filter;

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
## Date: 26th of September 2007
## Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
##-------------------------------------------------------------------
#

use strict;
use WebGUI::Macro;
use WebGUI::HTML;

=head1 NAME

Package WebGUI::Macro::filter;

=head1 DESCRIPTION

Macro for filtering HTML.

#-------------------------------------------------------------------

=head2 process ( html, [filter] )

I use this macro in the Password Recovery Template. Here the variable 
<tmpl_var recoverMessage> returns <ul><li><li> which produces empty 
bullets. The reason for this is that line 73 of Auth/WebGUI.pm adds 
list-tags ($error .= '<li>'.$i18n->get(3).'</li>';) and line 727 of 
the same module too. ($self->recoverPassword('<ul><li>'.$self->error.'</li></ul>'); 
The real solution would be to change Auth/WebGUI.pm. 

This macro is in fact an interface to WebGUI::HTML::filter.

The filter chosen is "all" from the following in HTML::filter:
Choose from "all", "none", "macros", "javascript", or "most". Defaults 
to "most". "all" removes all HTML tags and macros; "none" removes no 
HTML tags; "javascript" removes all references to javacript and macros; 
"macros" removes all macros, but nothing else; and "most" removes all 
but simple formatting tags like bold and italics.

=cut

sub process {
	my $session = shift;
	my $html = shift;

	my $html = WebGUI::HTML::filter($html,"all");
	
	return $html;

}
1;
