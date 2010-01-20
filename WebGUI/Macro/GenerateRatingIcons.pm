package WebGUI::Macro::GenerateRatingIcons;

use strict;

sub process {
    my $session = shift;
    my $rating  = shift;

    my $output  = '<div class="mannetjeGroot"></div>' x (int( $rating / 10 ));
    $output    .= '<div class="mannetjeKlein"></div>' x ($rating % 10);

    return $output;
}

1;
