package WebGUI::Macro::Karma;

#-------------------------------------------------------------------
# Karma macro is Copyright 2006 Colin Kuskie
#-------------------------------------------------------------------
# This software is distributed under the same license as WebGUI, the
# GPL.  Please refer to (docs/license.txt) that came with WebGUI
# before using this software.
#-------------------------------------------------------------------
# 						ckuskie@sterling.net
#-------------------------------------------------------------------

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::International;

=head1 NAME

Package WebGUI::Macro::Karma

=head1 DESCRIPTION

Macro for displaying the amount of karma the current user has

=head2 process ( [text] )

=head3 text

The text to be displayed to the user.  The text will be processed by
sprintf, using %d to represent the integer karma.

=cut

#-------------------------------------------------------------------
sub process {	
	my ($session, $text) = @_;
	my $i18n = WebGUI::International->new($session, 'Macro_Karma');
	$text = $text || $i18n->get('karma message');
	return sprintf($text, $session->user->karma);
}

1;
