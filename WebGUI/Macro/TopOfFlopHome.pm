package WebGUI::Macro::TopOfFlopHome;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
#use WebGUI::User;

=head1 NAME

Package WebGUI::Macro::TopOfFlopHome

=head1 DESCRIPTION

This macro lets the recipient confirm or deny a date

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=item collaborationUrl

The url of the Collaboration System to which this thread belongs

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session             = shift;
	my $templateUrl         = shift;
    my $collaborationUrl    = shift;
    my $form                = $session->form;
    my ($var,$thread);
	
    return 'This macro requires a template url' unless($templateUrl);
        
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    my $collaboration = WebGUI::Asset::Wobject::Collaboration->newByUrl($session,$collaborationUrl);	

    my ($threadId,$threadUrl,$ratingCount,$rating) = $session->db->quickArray("
	SELECT 
		asset.assetId, 
		assetData.url, 
		(select count(*) from Post_rating where Post_rating.assetId = Thread.assetId) as ratingCount, 	
		Post_rating.rating 
	from 	Thread 
	left join 
		asset on Thread.assetId=asset.assetId 
	left join 
		Post on Post.assetId=Thread.assetId and Thread.revisionDate = Post.revisionDate 
	left join 
		assetData on assetData.assetId=Thread.assetId and Thread.revisionDate = assetData.revisionDate 
	left join 
		Post_rating on Post_rating.assetId=Thread.assetId and Post_rating.userId = ?
	where 
		Post_rating.rating IS NULL 
	and 
		asset.parentId=? 
	and 
		asset.state='published' 
	and 
		asset.className='WebGUI::Asset::Post::Thread' 
	and 
		assetData.revisionDate=( select max(revisionDate) from assetData where assetData.assetId=asset.assetId and (status='approved' or status='archived') ) 
	and 
		status='approved' 
	group by assetData.assetId 
	order by ratingCount asc, `assetData`.`revisionDate` desc LIMIT 0,30;",
            [$session->user->userId,$collaboration->getId]);	

    if($threadId){
        $thread = WebGUI::Asset::Post::Thread->new($session,$threadId);
    }
    else{
        $var->{hasRatedAll} = 1;
    	my @threads = @{$collaboration->getThreadsPaginator->getPageData};
        # start at first thread 
        $thread = WebGUI::Asset::Post::Thread->new($session,$threads[0]->{assetId});
        $threadUrl  = $thread->getUrl;
        $threadId   = $thread->getId;
    }	

    my $threadProperties = $thread->get;
    $var->{thread_id}       = $threadId;
    $var->{thread_url}      = $threadUrl;
    $var->{thread_title}    = $threadProperties->{title};
    $var->{thread_synopsis} = $threadProperties->{synopsis};
    $var->{thread_content}  = $threadProperties->{content};

    if($threadProperties->{storageId}){
	my $storage 	= WebGUI::Storage->get( $session, $threadProperties->{storageId} );
	my $filename   	= $storage->getFiles->[0];
	if ( $storage->isImage( $filename ) ) {
            $var->{thread_image} 	= $storage->getUrl( $filename );
            $var->{thread_image_thumb} 	= $storage->getThumbnailUrl( $filename );		
        }
    }	
    
    return $template->process($var);
}



1;

#vim:ft=perl
