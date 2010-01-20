package WebGUI::Macro::GetParam;

use strict;

use URI;
use CGI;

sub process {
    my $session = shift;
    my $url     = shift || return 'GetParam: url required';
    my $param   = shift || return 'GetParam: param required';

    my $uri = URI->new( $url ) || return 'GetParam: Error, could not parse uri';

    return CGI->new( $uri->query )->param( $param );
}

1;

