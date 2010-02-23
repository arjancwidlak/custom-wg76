package WebGUI::Macro::XMLCollaboration;

##-------------------------------------------------------------------
## This macro is Copyright 2010 United Knowledge
## http://www.unitedknowledge.nl/
## Authors: Arjan Widlak
## Version: 0.1
## Date: 23th of February 2010
## Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
##-------------------------------------------------------------------


use strict;
use WebGUI::Asset;
use WebGUI::Asset::Template;

=head1 NAME

Package WebGUI::Macro::XMLCollaboration

=head1 DESCRIPTION

This macro returns a list of the first images of all threads in a Collaboration System. This macro is intended to work with the UK Player, that displayes these images as a flash-movie. Place this macro in a snippet with mime-type XML and configure the player to read it's content.xml from this snippet. Only one macro is needed on a site, since it receives the assetId of the Collaboration System.  

=head2 process (assetId)

=head3 assetId

The assetId of a Collaboration System.

=cut

#------------------------------------------------------------------------------



sub process {
    my $session = shift;
    my $assetId      = shift || return "No CS assetId was passed";
    my $templateId   = shift || "PBtmpl0000000000000121"; # Photogallery

    my $Collaboration = WebGUI::Asset->newByDynamicClass( $session,$assetId );
    my $p = $Collaboration->getThreadsPaginator;
    my %var = $Collaboration->getViewTemplateVars;
    $Collaboration->appendPostListTemplateVars(\%var,$p);
    return $Collaboration->processTemplate(\%var,$templateId);
}

1;

