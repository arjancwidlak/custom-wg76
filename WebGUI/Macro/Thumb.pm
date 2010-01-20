package WebGUI::Macro::Thumb;

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

=head1 NAME

Package WebGUI::Macro::Thumb

=head1 DESCRIPTION

Macro for returning the file system URL of the thumbnail of an Image Asset,
identified by it's filesystem URL.

#-------------------------------------------------------------------

=head2 process ( filesystemUrl )

returns the file system URL 

=head filesystemUrl

The URL to the Asset.

=cut

sub process {
	my $session = shift;
	my $avatarUrl = shift;
	my $filename;
	my $thumbnailFilename;
	my $thumbnailAvatarUrl;

	my @parts = split("/",$avatarUrl);
	$filename = pop(@parts);
	$thumbnailFilename = "thumb-".$filename;
	push(@parts,$thumbnailFilename);
	$thumbnailAvatarUrl = join("/",@parts);
	return "$thumbnailAvatarUrl";
}

1;
