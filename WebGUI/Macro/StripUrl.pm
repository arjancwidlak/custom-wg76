package WebGUI::Macro::StripUrl;

use strict;

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my $url = shift;

    $url =~ s/#.*$//;

	return $url;
}

1;


