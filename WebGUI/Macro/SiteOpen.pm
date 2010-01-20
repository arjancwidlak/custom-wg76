package WebGUI::Macro::SiteOpen;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;

=head1 NAME

Package WebGUI::Macro::SiteOpen

=head1 DESCRIPTION


=head2 process ( newHomepageUrl )

A asset Url that should be the new default page when the site is open.

=head3 newHomepageUrl

=head2 process ( templateUrl )

=head3 templateUrl

An asset Url of the template that is used to display this Macro.

=cut

#-------------------------------------------------------------------
sub process {
    my $session = shift;
    my $newHomepageUrl = shift;
    my $templateUrl = shift;

    return 'This macro requires a template url' unless($templateUrl);
    return 'This macro requires a new homepage url' unless($newHomepageUrl);

    my $newHomepageAsset = WebGUI::Asset->newByUrl($session,$newHomepageUrl);
    return 'Invalid new hompage url' unless($newHomepageAsset);

    if($session->form->process('openSite')){
        $session->setting->set('defaultPage',$newHomepageAsset->getId);
        WebGUI::Cache->new($session)->flush;
    } 
   
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    my $var;
    $var->{openSiteUrl}	= $session->url->page("openSite=1");	
    $var->{newHomeUrl}  = $session->url->gateway($newHomepageUrl);	

    return $template->process($var);
}


1;

