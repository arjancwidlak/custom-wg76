package WebGUI::Macro::RecentThreads;

use strict;

use WebGUI::Asset;

sub process {
    my $session     = shift;
    my $csId        = shift || return "Error: no cs id passed";
    my $templateId  = shift || return "Error: no template id passed";
    my $threadLimit = shift;

    # Instanciate collabortion system
    my $cs = WebGUI::Asset->newByDynamicClass( $session, $csId );
    return "Error: invalid cs id" unless $cs; 
#        unless ( $cs && $cs->get('className') =~ m/^WebGUI::Asset::Wobject::Collaboration"/ );

    # Instanciate template
    my $template = WebGUI::Asset::Template->new( $session, $templateId );
    return "Error: invalid template id" unless $template;

    # Provide all cs properties as tmpl_vars
    my $var = $cs->get;
    $var->{ url } = $cs->getUrl;
    
    # Fetch threads from cs
    my $threads = $cs->getLineage( [ "children" ], {
        returnObjects       => 1,
        includeOnlyClasses  => [ 'WebGUI::Asset::Post::Thread', 'WebGUI::Asset::IssuePost::IssueThread' ],
        limit               => $threadLimit,
        orderByClause       => 'creationDate desc',
    } );

    # And get all postdata from them
    my @threadLoop;
    foreach my $thread ( @{ $threads } ) {
        push @threadLoop, {
            %{ $thread->get },
            'url'               => $thread->getUrl,
            'collaboration.url' => $thread->getParent->getUrl,
        };
    }
    $var->{post_loop} = \@threadLoop;

    return $template->process( $var );
}

1;

