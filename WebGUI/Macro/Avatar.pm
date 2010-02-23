package WebGUI::Macro::Avatar;

#-------------------------------------------------------------------
## WebGUI is Copyright 2001-2005 Plain Black Corporation.
##-------------------------------------------------------------------
## Please read the legal notices (docs/legal.txt) and the license
## (docs/license.txt) that came with this distribution before using
## this software.
##-------------------------------------------------------------------
## http://www.plainblack.com                     info@plainblack.com
##-------------------------------------------------------------------
#
#
##-------------------------------------------------------------------
## This macro is Copyright 2007 United Knowledge
## http://www.unitedknowledge.nl/
## Author: Arjan Widlak
## Version: 0.1
## Date: 28th of August 2007
## Licence: GPL http://www.gnu.org/licenses/gpl-2.0.html
##-------------------------------------------------------------------
#

use strict;
use Switch;
use WebGUI::User;
use WebGUI::Macro;
use WebGUI::User;
use WebGUI::Storage;
use WebGUI::Storage::Image;

=head1 NAME

Package WebGUI::Macro::Avatar;

=head1 DESCRIPTION

Macro for displaying a users avatar, photo or other image. 

#-------------------------------------------------------------------

=head2 process ( userId, fieldName, alt1, [altImage], [alt2], [classname] )

Returns an XHTML 1.0 strict and WAI compliant image tag including alternate 
text. Optionally you can provide a url of an image that should be 
displayed if the user has no image in his profile. And an alternate 
text belonging to that image. 

=head3 userId

The id of the user in whose profile the image's storageId can be 
found. 

=head3 fieldName

The fieldName in the user profiling system in which the image's 
storageId can be found. 

=head3 alt1

The alternate text describing the image. You can use other macro's 
here, as long as they don't contain quotes. If no alternate text is 
given the macro will look in the profile for firstName, middleName 
and lastName. 

=head3 altImage

If there is no image in the users profile, display this image.

=head3 alt2

Of course the alternate image has a different alternate text, describing 
the image. Such as "no image found".

=head3 classname

Of course you might want to add a class to this image. 

=cut

sub process {
	my $session = shift;
	
	my $userId = shift;
	my $fieldName = shift || 'avatar';
	my $alt1 = shift;
	my $altImage = shift;
	my $alt2 = shift;
	my $className = shift;
	
	# temp variabelen:
	my ($filename, $nofile, $noalt, $url, $tag, $nameAsAlt); 

	# What do we need?
	# 1 create a user instance
	# 2 get this users profile info
	# 3 create a storage instance
	# 4 get the thumbnail url
	#
	# 1. Create a new user object
	my $user = WebGUI::User->new($session,$userId);
	#my $user = WebGUI::User->new($session,$session->form->process("uid"));
	# 2. get this users profile info
	my $fieldData = $user->profileField($fieldName);
	
	my $nofile = 1 if !$fieldData;
	# 3. create a storage instance
	my $storage = WebGUI::Storage->get($session,$fieldData) unless $nofile;
	
	# 4. get the thumbnail url
	# returns an array of files, (withouth the thumbs since recently)
	my @files = @{ $storage->getFiles } unless $nofile;
	
	my $aantal = @files;
	$nofile = 1 if $aantal < 1;
	unless ($nofile) {
		$filename = $files[0];
	}
	#get the path to the file
	$url = $storage->getUrl("thumb-".$filename) unless $nofile;
	
	my @name;
	my $i = 0;
	for ("firstName", "middleName", "lastName") {
		if ($user->profileField($_)) {
			$name[$i] = $user->profileField($_);
			$i++;
		}
	}
	$nameAsAlt = join(" ",@name);
	
	$tag = "<img src=\"";
	if ($url) {
		$tag .= $url;
	}else{
		$tag .= $altImage; }
	$tag .= "\" alt=\"";
	if 	($url && $alt1) 	{ $tag .= $alt1; }
	elsif 	($url && !$alt1)	{ $tag .= $nameAsAlt; }
	elsif	(!$url && $alt2)	{ $tag .= $alt2; }
	elsif	(!$url && !$alt2)	{ $tag .= "Sorry, shy, no picture."; }
	else { return "Did I forget something?"; }
	$tag .= "\" class=\"".$className if $className;
	$tag .= '" />';
	return $tag;

}
1;
