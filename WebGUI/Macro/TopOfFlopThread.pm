package WebGUI::Macro::TopOfFlopThread;

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

Package WebGUI::Macro::TopOfFlopThread

=head1 DESCRIPTION

This macro lets the recipient confirm or deny a date

=head2 process( $session, [@other_options] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=item threadId

The current thread

=item collaborationUrl

The url of the Collaboration System to which this thread belongs

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session             = shift;
	my $templateUrl         = shift;
    my $threadId            = shift;
    my $collaborationUrl    = shift;
    my $form                = $session->form;
    my $var;
	
    return 'This macro requires a template url' unless($templateUrl);
        
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);
    
    my $currentThread = WebGUI::Asset::Post::Thread->new($session,$threadId);

    # Set rating
    if($form->process('rateTopOfFlop') && ($currentThread->hasRated == 0)){
        my $threadToRateId = $form->process('topOfFlopThreadId');
        $session->db->write("insert into Post_rating (assetId,userId,ipAddress,dateOfRating,rating) values (?,?,?,?,?)",
            [$threadToRateId,
             $session->user->userId,
             $session->env->getIp,
             $session->datetime->time(),
             $form->process('topOfFlopRating'),]
        );
        my ($sum,$count) = $session->db->quickArray("select sum(rating), count(rating) from Post_rating where assetId=?",
            [$threadToRateId]);
        my $mean = $sum / ($count || 1);
        $var->{previousThreadRating} = sprintf("%.0f",$mean);
        my $previousThread = WebGUI::Asset::Post::Thread->new($session,$threadToRateId);
	$previousThread->update({rating=>$mean});
	$var->{previousThreadTitle} 	= $previousThread->get('title');
	$var->{previousThreadReplies} 	= $previousThread->get('replies');
	$var->{previousThreadUrl} 	= $previousThread->get('url');
    }

    # Set hasRatedAll value
    my $collaboration = WebGUI::Asset::Wobject::Collaboration->newByUrl($session,$collaborationUrl);
    my $threads = $collaboration->getLineage(['children'], {
                                        includeOnlyClasses => ['WebGUI::Asset::Post::Thread'],
                                        returnObjects => 1,
                                });
    my $hasRatedAll = 1;
    foreach my $thread (@$threads){
        if ($thread->hasRated == 0){
            $hasRatedAll = 0;
            last;
        }
    }

    # Get next thread
    my $nextTopOfFlopThread;
    if ($hasRatedAll){
        $nextTopOfFlopThread = $currentThread->getNextThread;
        unless($nextTopOfFlopThread){
            my @threads = @{$collaboration->getThreadsPaginator->getPageData};
            # start again at first thread
            $nextTopOfFlopThread = WebGUI::Asset::Post::Thread->new($session,$threads[0]->{assetId});
        }
    }
    else{
        $nextTopOfFlopThread = getNextUnratedThread($session,$currentThread,$collaboration);
    }
   
    $var->{hasRated}            = $currentThread->hasRated; 
    $var->{hasRatedAll}         = $hasRatedAll;
    $var->{nextTopOfFlopUrl}    = $nextTopOfFlopThread->getUrl;
    $var->{topOfFlopThreadId}   = $currentThread->getId;
    
    return $template->process($var);
}

sub getNextUnratedThread{
    my $session         = shift;
    my $currentThread   = shift;
    my $collaboration   = shift;
    my $nextThread      = $currentThread->getNextThread;

    unless($nextThread){
        my @threads = @{$collaboration->getThreadsPaginator->getPageData};
        # start again at first thread 
        $nextThread = WebGUI::Asset::Post::Thread->new($session,$threads[0]->{assetId}); 
    }

    if($nextThread->hasRated){
        getNextUnratedThread($session,$nextThread,$collaboration);
    }
    else{
        return $nextThread;
    }
}

1;

#vim:ft=perl
