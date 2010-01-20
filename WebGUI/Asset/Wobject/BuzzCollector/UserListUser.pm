package WebGUI::Asset::Wobject::BuzzCollector::UserListUser;

=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use Class::InsideOut qw(readonly private id register);
use Tie::IxHash;
use Clone qw/clone/;
use WebGUI::International;
use JSON;
use WebGUI::User;

private objectData => my %objectData;
readonly session => my %session;

=head1 NAME

Package WebGUI::Asset::Wobject::BuzzCollector::UserListUser

=head1 DESCRIPTION

Creates a form control that will allow you to select a form control type. It's meant to be used in conjunction with
the DynamicField form control.

=head1 SEE ALSO

This is a subclass of WebGUI::Form::SelectBox.

=head1 METHODS 

The following methods are specifically available from this class. Check the superclass for additional methods.

=cut

#-------------------------------------------------------------------

=head2 appendEditScreenFormElements ( form )

Appends form elements specific to this Item Type to a form object.

=cut

sub appendEditScreenFormElements {
    my $self        = shift;
    my $session     = shift;
    my $form        = shift;
    my $settings;
    
    my $i18n = WebGUI::International->new($session, 'Asset_BuzzCollector');

    if ($self->get('settings')){
        $settings = JSON->new->decode($self->get('settings')); 
    }
    $form->asset(
        -name       =>"userListId",
        -value      =>$settings->{userListId},
        -class      =>'WebGUI::Asset::Wobject::UserList',
        -label      =>$i18n->get('userlist label'),
        -hoverHelp  =>$i18n->get('userlist description'),
        );

    return $form;
}

#-------------------------------------------------------------------

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
                my $fieldId            = $field->getId;
                my $fieldLabel         = $field->getLabel;
                my $fieldValue         = $field->formField(undef,2,$user);
                # Create a seperate template var for each field
                my $fieldBase = $prefix.$fieldId;
                $var->{$fieldBase                          } = $fieldValue;
            }
        }
    return $var;
}


#-------------------------------------------------------------------

=head2 definition ( )

Definition for this class.

=cut

sub definition {
    my ($class, $session) = @_;
    tie my %properties, 'Tie::IxHash';
    my $definition = {
        properties  => \%properties,
    };
    my $properties = $definition->{properties};
    my $i18n = WebGUI::International->new($session);
    $properties->{settings} = {
        fieldType    => 'text',
        label        => '',#$i18n->get('Bucket Name','PassiveAnalytics'),
        hoverHelp    => '',#$i18n->get('Bucket Name help','PassiveAnalytics'),
        defaultValue => '',
    };
    $properties->{itemType} = {
        fieldType    => 'text',
        label        => '',#$i18n->get('regexp','PassiveAnalytics'),
        hoverHelp    => '',#$i18n->get('regexp help','PassiveAnalytics'),
        defaultValue => '',
    };
    return $definition;
}

#-------------------------------------------------------------------

=head2 get ( [ property ] )

Returns a hash reference of all the properties of this object.

=head3 property

If specified, returns the value of the property associated with this this property name. Returns undef if the
property doesn't exist. See crud_definition() in the subclass of this class for a complete list of properties.

=cut

sub get {
    my ($self, $name) = @_;

    if (defined $name) {
        return clone $objectData{id $self}{$name};
    }

    return clone $objectData{id $self};
}

#-------------------------------------------------------------------

=head2 getItemLoop  ( maxItems, maxItemAge )

Returns an arrayRef of hashRefs containing items.

=head3 maxItems

The number of items to return.

=head3 maxItemAge

The maximum age of the items to return in seconds.

=cut

sub getItemLoop {
    my $self        = shift;
    my $session     = shift;
    my $maxItems    = shift;
    my $maxItemAge  = shift;
    
    my $minDateCreated = time() - $maxItemAge;

    my %settings    = %{JSON->new->decode($self->get('settings'))};
    my $userlist    = WebGUI::Asset::Wobject::UserList->new($session,$settings{userListId});
    my $showGroupId = $userlist->get('showGroupId');
    my $hideGroupId = $userlist->get('hideGroupId');

    my @item_loop;
    my $users = $session->db->read("select userId, username, dateCreated from users where dateCreated > ? order by dateCreated desc"
        ,[$minDateCreated]);
    while (my $user = $users->hashRef) {
        my $userObject = WebGUI::User->new($session,$user->{userId});        
        next unless ($userObject->isInGroup($showGroupId));
        next if     ($userObject->isInGroup($hideGroupId));
        $user = appendUserProfileVars($session,$user,$userObject,'user_');
        $user->{itemType}           = 'User';
        $user->{isUser}             = 1;
        $user->{dateCreatedHuman}   = $session->datetime->epochToHuman($user->{dateCreated});
        push(@item_loop,$user); 
        last if (scalar(@item_loop == $maxItems));
    }

    return \@item_loop;
}

#-------------------------------------------------------------------

=head2 getLabel ( session )

Returns the human readable name of this BuzzCollector Item Type.

=cut

sub getLabel {
    my ($self, $session) = @_;
  
    my $settings = $self->get('settings'); 
    my %settings = %{JSON->new->decode($settings)};
    my $userListTitle = WebGUI::Asset::Wobject::UserList->new($session,$settings{userListId})->get('title');
    my $label =  $self->getName($session).' from '.$userListTitle;
    return $label;
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this BuzzCollector Item Type.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'Asset_BuzzCollector')->get('userlist user label');
}

#-------------------------------------------------------------------

=head2 hasSettings

Returns a boolean indicating whether this item type has any settings

=cut

sub hasSettings {
    return 1;
}

#-------------------------------------------------------------------

=head2 new ( session, id )

Constructor.

=head3 session

A reference to a WebGUI::Session.

=head3 id

A guid, the unique identifier for this object.

=cut

sub new {
    my ($class, $session, $id) = @_;
    my ($data,$properties);

    unless (defined $session && $session->isa('WebGUI::Session')) {
        WebGUI::Error::InvalidObject->throw(expected=>'WebGUI::Session', got=>(ref $session), error=>'Need a
session.');
    }
    unless ($id eq 'new'){
        $data = $session->db->getRow('BuzzCollector_item', 'itemId', $id);
    

    $properties = $class->definition($session)->{properties};
    foreach my $name (keys %{$properties}) {
        if ($properties->{$name}{serialize} && $data->{$name} ne "") {
            $data->{$name} = JSON->new->canonical->decode($data->{$name});
        }
    }
    }

    my $self = register($class);
    my $refId = id $self;
    $objectData{$refId} = $data;
    $session{$refId} = $session;
    return $self;
}

#-------------------------------------------------------------------

=head2 processSettingsFromFormPost ( form )

Returns a JSON string containging the settings for this Item Type from a form post.

=cut

sub processSettingsFromFormPost {
    my $form = shift;

    return JSON->new->encode({userListId=>$form->process('userListId')});
}

1;
