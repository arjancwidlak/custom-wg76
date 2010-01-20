package WebGUI::Macro::PostThumb;

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
use WebGUI::Asset;
use WebGUI::Asset::Post;

sub getImageUrl {
        my $self = shift;
        return undef if ($self->get("storageId") eq ""); 
        my $storage = $self->getStorageLocation;
        my $url;
        foreach my $filename (@{$storage->getFiles}) {
               if ($storage->isImage($filename)) {
                  $url = $storage->getUrl($filename);
                  last;
	       }
	}      
	return $url;
}
	
sub process {
	my $session = shift;
	
}

1;


