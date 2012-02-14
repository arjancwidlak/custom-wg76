package WebGUI::Macro::ProfileFieldPhoto;

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

=head1 NAME

Package WebGUI::Macro::ProfileFieldPhoto

=head1 DESCRIPTION

Macro for displaying an image based on a field in the user's profile if the user has no photo.

=head2 process( photoStorageId, replacementField, replacementPath, replacementExtension [, userId] )

If the user has no photo this macro tries to return an image url based on the profile field passed in for the user
passed in.  If not user is passed in, the current user in session
will be used.  
Example:
^ProfileFieldPhoto(<tmpl_var profile_field_photo_raw>,workName,/images/profilefield-photo/,jpg,<tmpl_var profile_user_id>);
If the user has no photo and the value for the user's 'workName' is 'United Knowledge', this will return:
/images/profilefield-photo/united-knowledge.jpg
(spaces in the value of the replacementField value will be replaced with dashes.)

=head3 photoStorageId

The value of the storageId of the user's photo, passed in using <tmpl_var profile_field_photo_raw>

=head3 replacementField

The url of the replacement image will be based on the value of this field

=head3 replacementPath

The path/base url of the replacement image, for example: /images/profilefieldphoto/

=head3 replacementExtension

The file extension of the replacement image, for example: jpg or gif

=head3 userId

optional userId of the user to return the field for.  If this field is
empty, the profile field for the default user will be returned

=head3 useThumbnail

Boolean that indicates that the thumbnail of the user's photo should be used.

=cut

#-------------------------------------------------------------------
sub process {
	my $session                 = shift;
    my $photoStorageId          = shift;
    my $replacementField        = shift;
    my $replacementPath         = shift;
    my $replacementExtension    = shift;
    my $userId                  = shift;
    my $useThumbnail            = shift;
    my ($filename,$storage);

    if($photoStorageId){
    	$storage = WebGUI::Storage->get( $session, $photoStorageId );
    	$filename   = $storage->getFiles->[0];
    }
	if ($filename){
        if($useThumbnail){
            return $storage->getThumbnailUrl( $filename );
        }
        else{
            return $storage->getUrl( $filename );
        }
	}
    else{
        return undef unless ($replacementField);
        my $user       = ($userId)
                       ? WebGUI::User->new($session,$userId)
               	       : $session->user
	                   ;	

        my $replacementFieldValue = $user->profileField($replacementField);
	    return undef unless ($replacementFieldValue);
        $replacementFieldValue =~ s/ /-/g;
        my $assetUrl = $replacementPath.$replacementFieldValue.'.'.$replacementExtension;
        my $asset = WebGUI::Asset->newByUrl( $session, $assetUrl );
        my $i18n = WebGUI::International->new( $session, 'Macro_ProfileFieldPhoto' );
        if ( not defined $asset ) {
            return $i18n->get('invalid url');
        }
        my $storageId = $asset->get('storageId');
        if( not defined $storageId ) {
            return $i18n->get('no storage');
        }
        my $filename = $asset->get('filename');
        if ( not defined $filename ) {
            return $i18n->get('no filename');
        }
        my $storage = WebGUI::Storage->get( $session, $storageId );
        return $storage->getUrl( $filename );
    }
}

1;
