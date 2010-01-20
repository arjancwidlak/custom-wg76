package WebGUI::Macro::PostIdForPage;

use strict;

=head1 NAME

WebGUI::Macro::PostIdForPage

=head1 DESCRIPTION

Returns the asset id of a thread or post that has a property containing the asset id of the current page.

=head1 USAGE

    ^PostIdForPage(property,scope);

=head2 property

The name of the property the asset id is stored in. Defaults to 'userDefined1'

=head2 scope

An asset id. If given, the search for a matching post or thread asset is limited to the confines of the asset
belonging to this id. If ommitted all assets will be searched.

=cut

sub process {
    my $session     = shift;
    my $property    = shift || 'userDefined1';
    my $scopeId     = shift;
    my $dbh         = $session->db->dbh;

    my $root 
        = $scopeId 
        ? WebGUI::Asset->newByDynamicClass( $session, $scopeId )
        : WebGUI::Asset->getRoot( $session )
        ;

    return "illegal property $property" unless $property =~ m{^[a-z0-9_-]+$}i;

    my $id = $root->getLineage( ['descendants'], {
        returnObjects   => 0,
        joinClass       => 'WebGUI::Asset::Post::Thread',
        whereClause     => 
            $dbh->quote_identifier($property) .'='. $dbh->quote( $session->asset->getContainer->getId ),
    } )->[0];

    return $id;
}

1;

