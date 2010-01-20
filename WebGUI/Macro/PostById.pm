package WebGUI::Macro::PostById;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
#use WebGUI::Asset;
#use WebGUI::Asset::Post;

=head1 NAME

Package WebGUI::Macro::PostById;

=head1 DESCRIPTION

Templatable macro for displaying a Post. This macro can be used in SQL 
Report Templates that search through posts. 

=head2 process ( assetId, templateId )

=head3 assetId

The assetId of the Post.

=head 3 templateId

The templateId of the template to use with this macro. It can be identical 
to what's in the post_loop of the collaboration template.

=cut

#-------------------------------------------------------------------

sub process {
        my $session = shift;

        my $assetId = shift;
	my $templateId = shift;

	my %var;
	
	# Create an instance of the Post, by its assetId.
        my $post = WebGUI::Asset->newByDynamicClass($session, $assetId);

	# Start collecting the data that will be used in the template:
        my @rating_loop;
        for (my $i=0;$i<=$post->get("rating");$i++) {
        	push(@rating_loop,{'rating_loop.count'=>$i});
        }
        my %lastReply;
        my $hasRead = 0;
        if ($post->get("className") =~ /Thread/) {
                $hasRead = $post->isMarkedRead;
        }
        my $url;
        if ($post->get("status") eq "pending") {
        	$url = $post->getUrl("revision=".$post->get("revisionDate"))."#".$post->getId;
        } else {
        	$url = $post->getUrl."#".$post->getId;
        }
        $var{'id'} = $post->getId;
	$var{'title'} = $post->getTitle;
	$var{'username'} = $post->get("username");
	$var{'synopsis'} = $post->get("synopsis");
	$var{"url"}= $url;
	$var{"rating_loop"} = \@rating_loop;
	$var{"content"} = $post->formatContent;
        $var{"status"} = $post->getStatus;
        $var{"thumbnail"} = $post->getThumbnailUrl;
        $var{"image.url"} = $post->getImageUrl;
	#$var{"dateSubmitted"} = $post->get("dateSubmitted");
	$var{"dateSubmitted"} = $post->get("creationDate");
        $var{"dateSubmitted.human"} = $session->datetime->epochToHuman( $post->get("creationDate") );
        $var{"userProfile.url"} = $post->getPosterProfileUrl;
        $var{"user.isVisitor"} = $post->get("ownerUserId") eq "1";
        $var{"edit.url"} = $post->getEditUrl;
	my $controls = $session->icon->delete('func=delete',$post->get("url"),"Delete").$session->icon->edit('func=edit',$post->get("url"));
        $var{'controls'} = $controls;
        $var{"user.hasRead"} = $hasRead;
        $var{"user.isPoster"} = $post->isPoster;

        $post->getTemplateMetadataVars(\%var);
	if ($post->get("className") =~ /Thread/) {
		$var{'rating'} = $post->get('threadRating');
	}
	return WebGUI::Asset::Template->new($session,$templateId)->process(\%var);
}
1;
