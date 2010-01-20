package WebGUI::Macro::MyMatches;

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
use WebGUI::User;
use WebGUI::ProfileField;

=head1 NAME

Package WebGUI::Macro::MyMatches

=head1 DESCRIPTION

This macro shows other users dates with whom the current user does not have a date with yet, who are in the same 'sector' but in a different kind of 'organisation'. They are ordered by the number of dates they have.

=head2 process( $session, [templateUrl, numberOfUsers, excludeGroup] )

The main macro class, Macro.pm, will call this subroutine and pass it

=over 4

=item templateUrl

A templateUrl

=item numberOfUsers

The maximum number of users to display

=item excludeGroup

Users in this group will be excluded

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session         = shift;
	my $templateUrl     = shift;
    my $numberOfUsers   = shift;
    my $excludeGroup	= shift;
	my $excludeGroupId;
    
    my $form            = $session->form;
    my $currentUserId   = $session->user->userId;
    my ($var,$date,$currentUserIsSender);
	
    return 'This macro requires a template url' unless($templateUrl);
        
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);

    $var->{url} = $session->url->page;

	if($excludeGroup){
		$excludeGroupId = $session->db->quickScalar("select groupId from groups where groupName=?",[$excludeGroup]);
	}	

    my @user_loop;
    my $query = "
	select 
		username, userId,
		(select count(*) from Dates where recipientUserId = users.userId OR senderUserId = users.userId) as dateCount
	from 
		users 
	left join 
		userProfileData using(userId) 
	where 
		sectorOrganisatie = ? and soortorganisatie != ?
	and
		(select count(*) from Dates where 
			(senderUserId = ? AND recipientUserId = users.userId) 
			OR (recipientUserId = ? AND senderUserId = users.userId)) = '0'
    and
        userId != ?
	and
	(select groupings.userId from groupings where groupings.userId = users.userId and groupings.groupId = 3) is null";
    if($excludeGroupId){
	$query .= "
	and
	(select groupings.userId from groupings where groupings.userId = users.userId and groupings.groupId = ".
	$session->db->quote($excludeGroupId).") is null";
    }
	$query .= "
	order by
		dateCount asc
    limit $numberOfUsers",
	my $users = $session->db->read($query,
    [   $session->user->profileField('sectorOrganisatie'),
        $session->user->profileField('soortorganisatie'),
        $currentUserId,
        $currentUserId,
        $currentUserId]);
    while (my $user = $users->hashRef) {
        my $userObject = WebGUI::User->new($session,$user->{userId});
        $user = appendUserProfileVars($session,$user,$userObject,'user_');
        push(@user_loop, $user);
    }   
    $var->{user_loop} = \@user_loop; 
   
    return $template->process($var);
}

sub appendUserProfileVars {
    my $session = shift;
    my $var     = shift;
    my $user    = shift;
    my $prefix  = shift;

        my $privacySettingsHash = WebGUI::ProfileField->getPrivacyOptions($session);
        $var->{'profile_category_loop' } = [];
        foreach my $category (@{WebGUI::ProfileCategory->getCategories($session,{ visible => 1})}) {
            my @fields = ();
            foreach my $field (@{$category->getFields({ visible => 1 })}) {
                next unless ($user->canViewField($field->getId,$session->user));
                next if ($field->getId eq 'email');
                my $rawPrivacySetting  = $user->getProfileFieldPrivacySetting($field->getId);
                my $privacySetting     = $privacySettingsHash->{$rawPrivacySetting};
                my $fieldId            = $field->getId;
		my $rawValue		= $user->profileField($fieldId);
                my $fieldLabel         = $field->getLabel;
                my $fieldValue         = $field->formField(undef,2,$user,undef,$rawValue);
		my $fieldRaw           = $rawValue;
                # Create a seperate template var for each field
                my $fieldBase = $prefix.$fieldId;
                $var->{$fieldBase.'_label'                          } = $fieldLabel;
                $var->{$fieldBase.'_value'                          } = $fieldValue;
                $var->{$fieldBase.'_privacySetting'                 } = $privacySetting;
                $var->{$fieldBase.'_privacy_is_'.$rawPrivacySetting } = "true";
		$var->{$fieldBase.'_raw'                            } = $fieldRaw;	
            }
        }
    return $var;
}

1;

#vim:ft=perl
