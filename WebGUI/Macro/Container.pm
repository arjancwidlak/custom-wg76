package WebGUI::Macro::Container;

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
use WebGUI::Utility;
#use WebGUI::Asset;

=head1 NAME

Package WebGUI::Macro::Container

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
	my $extraContainerClassNames = shift;
	my $assetId = shift;
	#my $includeSelf = shift || 0;
	my $asset;
	if (defined $assetId){
		$asset = WebGUI::Asset->new($session,$assetId) || $session->asset;
	}else{
		$asset = $session->asset;
	}
	return "" unless $asset;
	
	my @extraContainerClassNames = map {"WebGUI::Asset::".$_} split(/\+/,$extraContainerClassNames);
	my @containerClassNames = (@{$session->config->get("assetContainers")},@extraContainerClassNames);
	#print join(",",@containerClassNames)."<br>";
	#my $parentId = $asset->get("parentId");

	#my $parent = WebGUI::Asset->new($session,$parentId);
	my $startId;
	#if ($includeSelf){
	#	$startId = $assetId;
	#}else{
		$startId = $asset->get("parentId");
	#}
	my $container = getContainer($session,$startId,\@containerClassNames);
	return "" unless defined $container;
	return $container->get($property);

}

sub getContainer {
	
	my $session = shift;
	my $assetId = shift;
	my $asset = WebGUI::Asset->new($session,$assetId);
	my $containerClassNames = shift;
	#print join(",",@{ $containerClassNames })."<br>";
	return $asset if (length($asset->get("lineage")) == 6);
	#print "checking asset, title: ".$asset->getTitle()." class: ".$asset->get('className')."<br>";
	if (WebGUI::Utility::isIn($asset->get('className'),@{ $containerClassNames })){
		return $asset;
	}else{
		return getContainer($session,$asset->get("parentId"),$containerClassNames);
	}

}

1;
