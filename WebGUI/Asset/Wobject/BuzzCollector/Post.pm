package WebGUI::Asset::Wobject::BuzzCollector::Post;

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

Package WebGUI::Asset::Wobject::BuzzCollector::Post

=head1 DESCRIPTION

Creates a form control that will allow you to select a form control type. It's meant to be used in conjunction with
the DynamicField form control.

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
        -name       =>"collaborationId",
        -value      =>$settings->{collaborationId},
        -class      =>'WebGUI::Asset::Wobject::Collaboration',
        -label      =>$i18n->get('collaboration label'),
        -hoverHelp  =>$i18n->get('collaboration description'),
        );
    $form->selectBox(
        -name       =>"includeAssets",
        -value      =>$settings->{includeAssets} || 'threads',
        -options    =>{ 
                        threads => $i18n->get('includeAssets threads label'),
                        replies => $i18n->get('includeAssets replies label'),
                        both    => $i18n->get('includeAssets both label'),
                        },
        -label      =>$i18n->get('includeAssets label'),
        -hoverHelp  =>$i18n->get('includeAssets description'),
        );

    return $form;
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
        label        => '',
        hoverHelp    => '',
        defaultValue => '',
    };
    $properties->{itemType} = {
        fieldType    => 'text',
        label        => '',
        hoverHelp    => '',
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
    my $collaboration    = WebGUI::Asset::Wobject::Collaboration->new($session,$settings{collaborationId});

    my @includeOnlyClasses   =      $settings{includeAssets} eq 'threads' ? ('WebGUI::Asset::Post::Thread')
                                :   $settings{includeAssets} eq 'replies' ? ('WebGUI::Asset::Post')
                                :   ('WebGUI::Asset::Post::Thread','WebGUI::Asset::Post');

    my @item_loop;
    my $whereClause = 'creationDate > '.$minDateCreated;
    my $items = $collaboration->getLineage(['descendants'], {
                                        includeOnlyClasses  => \@includeOnlyClasses,
                                        returnObjects       => 1,
                                        limit               => $maxItems,
                                        whereClause         => $whereClause,
                                        orderByClause       => 'creationDate desc',
                                });
    foreach my $item (@$items) {
        my $itemProperties = $item->get;
        $itemProperties->{itemType}         = 'Post';
        $itemProperties->{isPost}           = 1;
        $itemProperties->{dateCreated}      = $itemProperties->{creationDate};
        $itemProperties->{dateCreatedHuman} = $session->datetime->epochToHuman($itemProperties->{dateCreated});
        push(@item_loop,$itemProperties); 
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
    my $collaborationTitle = WebGUI::Asset::Wobject::Collaboration->new($session,$settings{collaborationId})->get('title');
    my $label =  $self->getName($session).': '.$collaborationTitle;
    return $label;
}

#-------------------------------------------------------------------

=head2 getName ( session )

Returns the human readable name of this BuzzCollector Item Type.

=cut

sub getName {
    my ($self, $session) = @_;
    return WebGUI::International->new($session, 'Asset_BuzzCollector')->get('collaboration post label');
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

    return JSON->new->encode({  collaborationId =>$form->process('collaborationId'),
                                includeAssets   =>$form->process('includeAssets')   });
}

1;
