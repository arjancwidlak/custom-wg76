package WebGUI::Macro::ThreadAttachment;

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
use WebGUI::Asset;
use WebGUI::Storage;
use WebGUI::International;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Macro::ThreadAttachment

=head1 DESCRIPTION

Macro for returning the file system URL to a Thread's attachment,
identified by it's assetId or URL.

#-------------------------------------------------------------------

=head2 process ( assetId/url, property )

returns the file system URL if url is the URL for an Asset in the
system that has storageId and filename properties.  If no Asset
with that URL exists, then an internationalized error message will
be returned.

=head3 assetId/url

The assetId the Asset.

=cut

sub process {
	my $session = shift;
    my $assetIdOrUrl = shift;
    my $property = shift || 'url';
    my $silent = shift || 1;
    my $output = shift || '^0;';
    my $result;
	
    my $asset = WebGUI::Asset->newByDynamicClass($session,$assetIdOrUrl);
	
    if (not defined $asset) {
        $asset = WebGUI::Asset->newByUrl($session,$assetIdOrUrl);
	}
    if (not defined $asset) {
        if ($silent){
            return '';
        }
        else{
            return 'invalid assetId or url';
        }
    }
	my $storageId = $asset->get('storageId');
	if (not defined $storageId) {
        if ($silent){
            return '';
        }
        else{
    		return 'no storage found';
        }
	}
    my $storage = WebGUI::Storage->get($session,$storageId);

    my $filename   = $storage->getFiles->[0];
    if(!$filename){
        if ($silent){
            return '';
        }
        else{
            return 'no file found';
        }
    }

    if ($property eq 'thumb'){
        if ( $storage->isImage( $filename ) ) {
            $result = $storage->getThumbnailUrl( $filename );
        }
        elsif ($silent){
            return '';
        }
        else{
            return 'file is not an image';
        }
    }
    elsif ($property eq 'url'){
    	$result = $storage->getUrl($filename);
    }
    elsif($property eq 'filesize'){
        $result = WebGUI::Utility::formatBytes($storage->getFileSize($filename));
    }
    elsif($property eq 'icon'){
        $result = $storage->getFileIconUrl($filename);
    }
    elsif($property eq 'extension'){
        $result = $storage->getFileExtension($filename);
    }
    else{
        if ($silent){
            return '';
        }
        else{
            return 'unkown property: '.$property;
        }
    }
    if ($result){
        $output =~ s/\^(\d+)\;/$result/g;
        return $output;
    }
    else{
        return '';
    }

}


1;
