package WebGUI::Macro::substr;

#
###-------------------------------------------------------------------
### This macro is Copyright 2008 Oqapi
### http://www.oqapi.nl/
### Author: Joeri de Bruin
### Version: 1
### Date: 21 january 2008
### Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
###-------------------------------------------------------------------
##

use strict;
use WebGUI::Macro;

=head1 NAME

Package WebGUI::Macro::substr;

=head1 DESCRIPTION

Macro for the powerfull Perl substr function. See for usage also Perl documentation

=head2 process ( text, offset [, length[, replacement]] )

=head3 text 

The source text for usage with the function

=head3 offset

The offset is the location from wich the substring is taken

=head3 length

The number of characters wich are returned. This parameter is optional. If not given, the remaining part after the
offset is returned.

=head3 replacement

Thist text is inserted on the place text was removed by the function. This parameter is optional. If not given
there will be no replacement for the removed characters.

=cut

#-------------------------------------------------------------------
sub process {
    my $session = shift;
    my $text = shift;
    my $offset = shift;
    my $length = shift;
    my $replacement = shift;
    if (defined $replacement)
    {
        substr $text, $offset, $length, $replacement;
        return $text;
    } elsif (defined $length)
    {
        return substr $text, $offset, $length;
    } else {
	    return substr $text, $offset;
    }
}
1;
