package WebGUI::Macro::FileUrlById;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
#use WebGUI::Asset;
#use WebGUI::Storage;
#use WebGUI::International;

=head1 NAME

Package WebGUI::Macro::FileUrlById

=head1 DESCRIPTION

Macro for returning the file system URL to a File or Image Asset,
identified by it's asset URL.

#-------------------------------------------------------------------

=head2 process ( assetId, returnFileName, returnThumb )

returns the file system URL if assetId is the ID for an Asset in the
system that has storageId and filename properties or if the assetId is a storageId.  If no Asset or storage
with that ID exists, then an i or if the assetId is a storageIdnternationalized error message will
be returned.

=head assetId

The assetId of a File or Image Asset, or a storageId.

=head returnFileName

Boolean indicating if the macro will return only the File Name instead of a url.

=head returnThumb

Boolean indicating that a thumbnail should be returned

=cut

sub process {
	my $session = shift;
    my $assetId = shift;
	my $returnFileName = shift;
	my $returnThumb = shift;
	my $asset;

	my $isAssetId = $session->db->quickScalar("select count(*) from asset where assetId = ?",[$assetId]);
	my $i18n = WebGUI::International->new($session, 'Macro_FileUrl');
	if ($isAssetId) {
		$asset = WebGUI::Asset->new($session,$assetId);
	}
	else {
		#return $i18n->get('invalid assetId');
		my ($url,$filename) = getUrlByStorageId($session,$assetId,$returnThumb);
		if (not defined $url) {
			return $i18n->get('no storage');
		}elsif ($returnFileName){
			return $filename;
		}else{
			return $url;
		}

	}
	my $storageId = $asset->get('storageId');
	if (not defined $storageId) {
		return $i18n->get('no storage');
	}
	my $filename = $asset->get('filename');
	if (not defined $filename) {
		return $i18n->get('no filename');
	}
	if ($returnFileName){
        return $filename;
        }else{
		my $storage = WebGUI::Storage->get($session,$storageId);
		return $storage->getUrl($filename);
	}
}

sub getUrlByStorageId {
	my $session = shift;
	my $storageId = shift;
	my $returnThumb = shift;
        my $file = WebGUI::Storage->get($session,$storageId);
        my $fileUrl = '';
	my $fileName = '';
        if ($file) {
                #Get url from storage object.
                foreach my $fileName (@{$file->getFiles}) {
                        #if ($avatar->isImage($imageName)) {
			my $isThumb;
			$isThumb = 1 if ($fileName =~ m/^thumb-/);
			#print "retrunThumb = '".$returnThumb."', isThumb = '".$isThumb."'<br>";
			if (($returnThumb && $isThumb) || (($returnThumb eq "" || $returnThumb eq "0") && $isThumb eq "")){
				#$fileName = "thumb-".$fileName;
				$fileUrl = $file->getUrl($fileName);
				return ($fileUrl,$fileName);
				last;
			}
                                #$fileUrl = $file->getUrl($fileName);
                                #last;
                        #}
                }
        }
        return ($fileUrl,$fileName);
}


1;
