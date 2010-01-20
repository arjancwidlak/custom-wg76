package WebGUI::Macro::SetRedirectAfterLogin;

use strict;

sub process {
    my $session = shift;

    my $referer = $session->url->getRefererUrl;
    $referer 	= $session->form->process('ral') if $session->form->process('ral');
#    $referer 	= undef unless $session->user->userId eq '1';

#    return '' if $referer eq $session->asset->get('url');

    $referer =~ s{^/?(.+)$}{/$1};

    $session->scratch->set( 'redirectAfterLogin', $referer );
#    $session->scratch->delete( 'redirectAfterLogin' ) unless defined $referer;

    return '';
}

1;

