package WebGUI::Macro::PostProperties;

use strict;

use WebGUI::Asset;
use WebGUI::Asset::Template;

sub process {
    my $session     = shift;
    my $postId      = shift;
    my $templateId  = shift;

    my $post = WebGUI::Asset->newByDynamicClass( $session, $postId );
    return "Invalid postId [$postId]" unless $post;

    my $template    = $session->stow->get( "PostProperties_$templateId" );
    if (!$template) {
        $template   = WebGUI::Asset::Template->new( $session, $templateId );
        return "Invalid templateId [$templateId]" unless $template;
        $template->prepare;

        $session->stow->set( "PostProperties_$templateId", $template );
    }

    my $var = $post->getTemplateVars;
    return $template->process( $var );
}

1;


