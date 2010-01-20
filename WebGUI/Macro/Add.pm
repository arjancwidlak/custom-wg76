package WebGUI::Macro::Add;

use strict;

sub process {
	my $session = shift;

	my $total = 0;
	$total += $_ for @_;

	return $total;
}

1;

