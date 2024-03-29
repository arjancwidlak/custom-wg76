package WebGUI::Macro::Root;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Asset;

=head1 NAME

Package WebGUI::Macro::Root

=head1 DESCRIPTION

Macro for returning the title of the root for this page.

=head2 process ( )

If an asset exists in the session object cache and and it's
topmost parent (root) can be found the title for that asset
is returned.  Otherwise an empty string is returned.

=cut

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my $property = shift || "title";
	my $assetId = shift;
	my $asset;
        if ($assetId){
		$asset = WebGUI::Asset->new($session,$assetId) || $session->asset;
        }else{
                $asset = $session->asset;
        }
        return "" unless $asset;

	my $lineage = $asset->get("lineage");
	return $asset->getTitle
		if (length($lineage) == 6); ##I am the super root.

	##Get my root.
	$lineage = substr($lineage,0,12);
	my $root = WebGUI::Asset->newByLineage($session,$lineage);

	return "" unless defined $root;
	return $root->get($property);	
}


1;
