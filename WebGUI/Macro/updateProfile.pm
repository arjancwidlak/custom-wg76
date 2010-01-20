package WebGUI::Macro::updateProfile; 

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
use WebGUI::Macro;
use WebGUI::User;
use WebGUI::Form;
use WebGUI::Storage;
use WebGUI::Storage::Image;

#-------------------------------------------------------------------
sub my_validateProfileData {
	my $session = shift;
	my @updatedFields = @_;
        my %data = ();
        my $error = "";
        my $warning = "";
        my $i18n = WebGUI::International->new($session);

	## Niet voor elk profielveld, maar voor die in het formulier:
	## Hier kunnen velden tussen zitten die niet bekend zijn in het profiel
 	#foreach my $field (@{WebGUI::ProfileField->getEditableFields($session)}) {
	my $matchResult;
        my $params = $session->form->paramsHashRef;
        foreach my $fieldInProfile (@{WebGUI::ProfileField->getEditableFields($session)}) {
        	my $profileFieldName = $fieldInProfile->getId;
		foreach my $fieldReceived (keys %{$params}) {

			## All fields that are already updated should be skipped
			# The greatest risk is avatar and file fields being updated with old values
			# But if it's updated it's in updatedFields
			# However if updatedFields is empty it will always match
			# so, we only skip if it's not empty
			my $values = "@updatedFields";
			#$matchResult .= "fieldReceived match and not empty don't process, next<br />" if (($fieldReceived =~ $values) && ($values ne ""));
			#$matchResult .= "values is empty: $values<br />" if $values eq "";
			#$matchResult .= "field does not match: $fieldReceived, $values<br />";
			#$matchResult .= "fields are equal: $fieldReceived, $profileFieldName<br />" if $profileFieldName eq $fieldReceived;
			
			## Exclude if already updated
			next if (($fieldReceived =~ $values) && ($values ne ""));
			
			## Exclude everything that's not received.
			next unless $fieldReceived eq $profileFieldName;
			
			## Exclude the normal File and Image fields
			my $fieldType = $fieldInProfile->get("fieldType");
			next if (($fieldType eq "Image") or ($fieldType eq "File"));

			## Start the real work
                	my $fieldValue = $fieldInProfile->formProcess;
                	if (ref $fieldValue eq "ARRAY") {
                	        $data{$fieldInProfile->getId} = $$fieldValue[0];
                	} else {
                	        $data{$fieldInProfile->getId} = $fieldValue;
                	}
                	if ($fieldInProfile->isRequired && $data{$fieldInProfile->getId} eq "") {
                	        $error .= '<li>'.$fieldInProfile->getLabel.' '.$i18n->get(451).'</li>';
                	} elsif ($fieldInProfile->getId eq "email" && WebGUI::Operation::Profile::isDuplicateEmail($session,$data{$fieldInProfile->getId})) {
                	        $warning .= '<li>'.$i18n->get(1072).'</li>';
                	}
                	if ($fieldInProfile->getId eq "language" && $fieldValue ne "") {
                	        unless (exists $i18n->getLanguages()->{$fieldValue}) {
                	                $error .= '<li>'.$fieldReceived->getLabel.' '.$i18n->get(451).'</li>';
                        	}
	               	}
	        }
	}
	#return $matchResult;
        return (\%data, $error, $warning);
}
#-------------------------------------------------------------------

sub process {
	my $session = shift;
	my $newLocation = shift;
	my $confirmMessage = shift;
	my $userId ='';
	unless($session->user->userId) {
		$userId = 		WebGUI::Form::Hidden->new($session,{name => 'userId'})->getValueFromPost;	
	}
	my $user = WebGUI::User->new($session,$session->user->userId);
	return if $userId eq '1';
	my $messages;		#errors display them if there are messages.
	my $fieldsUpdated = 0; 	#only go to the new location if fields are updated.
	
	## 
	# I would like to upload a new file/photo immediately, not first delete it and later return
	# so I'm going to write my own sub getValueFromPost, that can do that
	# first I'm going to loop through alle editable profilefields to look for fields of type File/Image
	# those will be processed first by my_getValueFromPost
	# I do not use validateProfileData on these files - data is not validated - because validateProfileFields 
	# calls formProcess and actually uploads the files without returning the id. Perhaps this id can be retrieved
	# but that's something for another time.
	# 
	# while we're in the loop, if not type File/Image, we might as well do the other thing: validateProfileData
	# I wrote my own sub validateProfileData, because the original forces you to present all required fields.
	# #
	
	## Have the received name/value pairs accessible:
	my $params = $session->form->paramsHashRef;
	my @namesReceived = keys %{$params};

	## Record updated file/images fields
	my @updatedFiles;

	my $received;
	
	## loop throught all editable profile fields
	foreach my $fieldInProfile (@{WebGUI::ProfileField->getEditableFields($session)}) {
		## Here getId gives the Name of the profileField in the database
		my $fieldName = $fieldInProfile->getId;

		my $valueReceived = $params->{$fieldName."_file"};
		
		## If no value is received, we leave the field for what it is.
		# Only if a new value is received, we act
		if ($valueReceived) {
			## is this one of the file/image type? 
			# It should be, cause we added _file to the fieldName
			my $fieldType = $fieldInProfile->get("fieldType");
			if (($fieldType eq "Image") or ($fieldType eq "File")) {

				$received .= $valueReceived ." in files<br />";
				
				## Record this field of type File/Image is updated
				push @updatedFiles,$fieldName;
				
				## Get the storageId of the old one if it exists
				# Note: the new file is given with a name that ends on _file
				# the old value has the same name without file
				# fieldName comes from the database and does not have the _file 
				my $storageId = $params->{$fieldName};
				
				my $storage;
				if ($storageId) {
					## Delete it
					$storage = WebGUI::Storage::Image->get($session,$storageId) if $fieldType eq "Image";
					$storage = WebGUI::Storage::File->get($session,$storageId) if $fieldType eq "File";
					$storage->delete();
				} else {
					#$storage = WebGUI::Storage->create($session);
					# if a new storage location is created, get it's Id
					#$storageId = $storage->getId;
				}
				## In alle cases: create a new storage location
				my $newStorage;
				$newStorage = WebGUI::Storage::Image->create($session,$storageId) if $fieldType eq "Image";
				$newStorage = WebGUI::Storage::File->create($session,$storageId) if $fieldType eq "File";
				
				## upload the new one
				$newStorage->addFileFromFormPost($fieldName."_file",1000);
				
				my @files = @{ $newStorage->getFiles };
				if (scalar(@files) < 1) {
					$newStorage->delete;
					$messages .= "Error: $fieldName niet goed ontvangen. Bestand te groot?<br />";
				} else {
					## get the new StorageId
					my $newStorageId = $newStorage->getId;

					## If it's an image, generate a thumbnail
					my $file = $newStorage->getFiles->[0] if $fieldType eq "Image";
					my $success = $newStorage->generateThumbnail($file) if $fieldType eq "Image";
				
					## update the users profile
					$user->profileField($fieldName,$newStorageId);
					$fieldsUpdated++;
				}
			}
			
		}
	}
	
	## Files that are not updated, but kept, should be updated:
	foreach my $fieldReceived (keys %{$params}) {
		## We can encounter three types of input files, the name, the name ending on _file and _action
		# we  only pay attention to _file, if this one does *not* match with updatedFiles, then
		# we update that field.
		my $updatedNames = "@updatedFiles";
		if ($updatedNames eq "" && $fieldReceived =~ /_file$/ ) {
			## updatedNames is empty, it will always match, update all realNames
			my $realName = $fieldReceived;
			$realName =~  s/_file$//;
			$user->profileField($realName,$params->{$realName});
		}else{
			if (($fieldReceived) =~ /_file$/ && !($fieldReceived =~ $updatedNames)) {
				my $realName = $fieldReceived;
				$realName =~  s/_file$//;
				$user->profileField($realName,$params->{$realName});
			}
			
		}
	}
	## We now have all file-type files in my @updatedFiles
	# They are uploaded and updated in the profile
	# We are going to pass this array to my_validateProfileData, so it can be excluded there
	my ($profile, $fieldName, $error, $u, $warning);
	($profile, $error, $warning) = my_validateProfileData($session, @updatedFiles);
	$messages .= $error;
	$messages .= $warning;
	
	my $match;
	foreach my $field ( keys %{$profile} ) {
		# In this loop are only the fields that need to be updated
		# all others are excluded in my_validateProfileData that builds $profile
		$user->profileField($field,$profile->{$field});
		$fieldsUpdated++;
	}
	## Where do we go?
	# If not ok, go to the current location, display messages
	return $messages if $messages;
	# If ok, go to the new location
	return ($session->http->setRedirect($newLocation),"$confirmMessage") if $fieldsUpdated > 0;
	#return; 
}
1;
