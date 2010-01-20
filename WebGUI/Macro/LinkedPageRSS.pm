package WebGUI::Macro::LinkedPageRSS;

use strict;

use WebGUI::Asset;
use WebGUI::Asset::Wobject::Layout;
use WebGUI::Asset::Template;

sub process {
    my $session     = shift;
    my $csId        = shift;
    my $limit       = shift || 10;
    my $templateId  = shift;

    my $cs = WebGUI::Asset->newByDynamicClass( $session, $csId );
    return "Invalid assetId [$csId]" unless $cs && $cs->isa( 'WebGUI::Asset::Wobject::Collaboration' );

    # Fetch recent Posts
    my $posts   = $cs->getLineage( ['descendants'], {
        returnObjects       => 1,
        includeOnlyClasses  => ['WebGUI::Asset::Post'],
        orderByClause       => 'revisionDate desc',
        limit               => $limit,
    } );

    my @items;
    foreach my $post ( @{ $posts } ) {
        my $layout = WebGUI::Asset::Wobject::Layout->new( $session, $post->getThread->get('userDefined1') );

        my %properties = %{ $post->get };
        %properties    = (
            ( map { 'post_' . $_ => $properties{$_} } keys %properties ),
            %{ $layout->get },

            post_url    => $post->getUrl,
            url         => $layout->getUrl,
            pubDate     => $session->datetime->epochToMail( $post->get('revisionDate') ),
        );

        push @items, \%properties;
    }

    my $var = {
        %{ $cs->get },
        url         => $cs->getUrl,
        item_loop   => \@items,
    };

    if ( $templateId ) {
        my $template = WebGUI::Asset::Template->new( $session, $templateId );
        return "Invalid template [$templateId]" unless $template && $template->isa( 'WebGUI::Asset::Template' );

        return $template->process( $var );
    }
    else {
        return WebGUI::Asset::Template->processRaw( $session, getDefaultTemplate(), $var );
    }
}

sub getDefaultTemplate {
    return <<XML;
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
    <title><tmpl_var title></title>
    <link><tmpl_var url></link>
    <description><tmpl_var description></description>
    <tmpl_loop item_loop>
    <item>
        <title><tmpl_var title></title>
        <link><tmpl_var url></link>
        <description><tmpl_var post_synopsis></description>
        <guid isPermaLink="true"><tmpl_var url></guid>
        <pubDate><tmpl_var pubDate></pubDate>
    </item>
    </tmpl_loop>
</channel>
</rss>
XML

}

1;

