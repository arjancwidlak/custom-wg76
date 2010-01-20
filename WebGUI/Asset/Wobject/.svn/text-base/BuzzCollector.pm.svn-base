package WebGUI::Asset::Wobject::BuzzCollector;

$VERSION = "1.0.0";

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
use Tie::IxHash;
use WebGUI::International;
use WebGUI::Pluggable;
use WebGUI::Utility;
use Module::Find qw(findallmod);
use base 'WebGUI::Asset::Wobject';

#-------------------------------------------------------------------

=head2 definition ( )

defines wobject properties for New Wobject instances.  You absolutely need 
this method in your new Wobjects.  If you choose to "autoGenerateForms", the
getEditForm method is unnecessary/redundant/useless.  

=cut

sub definition {
	my $class = shift;
	my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session, 'Asset_BuzzCollector');
	my %properties;
	tie %properties, 'Tie::IxHash';
	%properties = (
		templateId =>{
			fieldType       =>"template",  
			defaultValue    =>'BuzzCollectorTmpl00001',
			tab             =>"display",
			noFormPost      =>0,  
			namespace       =>"BuzzCollector", 
			hoverHelp       =>$i18n->get('template description'),
			label           =>$i18n->get('template label'),
		},
        maxItemsPerType=>{
            fieldType       =>"integer",
            tab             =>"display",
            defaultValue    =>"5",
            hoverHelp       =>$i18n->get('max items per type description'),
            label           =>$i18n->get('max items per type label'),
        },
        maxItemAge=>{
            fieldType       =>"interval",
            tab             =>"display",
            defaultValue    =>60*60*24*7,
            hoverHelp       =>$i18n->get('max item age description'),
            label           =>$i18n->get('max item age label'),
        },
        sort=>{
            fieldType       =>"selectBox",
            tab             =>"display",
            defaultValue    =>"dateCreated",
            options         =>{
                                dateCreated => 'by date',
                                mixed       => 'mixed by type',
                                },
            hoverHelp       =>$i18n->get('sort description'),
            label           =>$i18n->get('sort label'),
        },
	);
	push(@{$definition}, {
		assetName=>$i18n->get('assetName'),
		icon=>'BuzzCollector.gif',
		autoGenerateForms=>1,
		tableName=>'BuzzCollector',
		className=>'WebGUI::Asset::Wobject::BuzzCollector',
		properties=>\%properties
		});
        return $class->SUPER::definition($session, $definition);
}


#-------------------------------------------------------------------

=head2 duplicate ( )

duplicates a New Wobject.  This method is unnecessary, but if you have 
auxiliary, ancillary, or "collateral" data or files related to your 
wobject instances, you will need to duplicate them here.

=cut

sub duplicate {
	my $self = shift;
	my $newAsset = $self->SUPER::duplicate(@_);
	return $newAsset;
}

#-------------------------------------------------------------------

=head2 getEditForm ( )

returns the tabform object that will be used in generating the edit page for New Wobjects.
This method is optional if you set autoGenerateForms=1 in the definition.

=cut

sub getEditForm {
	my $self = shift;
	my $tabform = $self->SUPER::getEditForm();
=cut
	$tabform->getTab("display")->checkList(
		-value      =>$self->getValue("templateId"),
		-label      =>WebGUI::International::get("item types label","Asset_BuzzCollector"),
        -hoverHelp  =>WebGUI::International::get("item types description","Asset_BuzzCollector"),
		-options    =>{userlist => ''},
	);
=cut	
	return $tabform;
}

#-------------------------------------------------------------------

=head2 getItem  ( itemId )

Returns a hash reference of the properties of an item.

=head3 itemId

The unique id of an item.

=cut

sub getItem {
    my ($self, $itemId) = @_;
    return $self->session->db->quickHashRef("select * from BuzzCollector_item where itemId=?",[$itemId]);
}

#-------------------------------------------------------------------

=head2 getItemLoop  ( sort )

Returns an arrayRef of hashRefs containing item.

=head3 itemId

The unique id of an item.

=cut

sub getItemLoop {
    my $self    = shift;
    my $session = $self->session;
    my (@item_loop,@item_loops);

    #my $itemCount = $session->db->read("select count(*) from BuzzCollector_item where buzzCollectorId=?"
    #    ,[$self->getId]);


    my $itemCount = 0;
    my $maxItemsPerType = $self->get('maxItemsPerType');
    # get item definitions
    my $items = $session->db->read("select * from BuzzCollector_item where buzzCollectorId=?"
        ,[$self->getId]);
    while (my $item = $items->hashRef) {
        $itemCount++;
        # get items for each item definition
        my $itemObject = eval { WebGUI::Pluggable::instanciate(
        'WebGUI::Asset::Wobject::BuzzCollector::'.ucfirst($item->{itemType}), 'new',[$session,$item->{itemId}]) };
        if ($self->get('sort') eq 'dateCreated'){
            push(@item_loop, @{$itemObject->getItemLoop($session,$maxItemsPerType,$self->get('maxItemAge'))});
        }
        else{
            my $loop = $itemObject->getItemLoop($session,$maxItemsPerType,$self->get('maxItemAge'));
            if (scalar @$loop){
                push(@item_loops, {
                                loop => $loop,
                                maxDateCreated =>$loop->[0]->{dateCreated},
                                });
            }
        }
    }
    if($self->get('sort') eq 'dateCreated'){
        @item_loop = sort {$b->{dateCreated} <=> $a->{dateCreated}} @item_loop;
    }
    else{
        # sort loops by most recent in loop
        @item_loops = sort {$b->{maxDateCreated} <=> $a->{maxDateCreated}} @item_loops;

        # add items from loops per type to mixed loop
        for (my $item_count = 0; $item_count < $maxItemsPerType; $item_count++) {
            for (my $loop_count = 0; $loop_count < scalar @item_loops; $loop_count++) {
                if ($item_loops[$loop_count]->{loop}->[$item_count]){
                    push(@item_loop,$item_loops[$loop_count]->{loop}->[$item_count]);
                }
            }
        }
    }

    return \@item_loop;
}

#-------------------------------------------------------------------

=head2 getItemTypes (  )

Returns a hash reference of item types and human readable names. Defaultly returns all that have
isDynamicCompatible() set to 1, but if types is specified in the constructor, will return the ones from that list.

=cut

sub getItemTypes {
    my $self = shift;
    my @types;
        my @classes = findallmod 'WebGUI::Asset::Wobject::BuzzCollector';
        for my $class (@classes) {
            if ($class =~ /^WebGUI::Asset::Wobject::BuzzCollector::(.*)/) {
                my $type = $1;
                push @types, $type;
            }
        }
    my %itemTypes = ();
    foreach my $type (@types) {
        $itemTypes{$type} = WebGUI::Pluggable::instanciate(
            'WebGUI::Asset::Wobject::BuzzCollector::'.ucfirst($type), 'getName',[$self->session]);
    }
    return \%itemTypes;
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
	$template->prepare;
	$self->{_viewTemplate} = $template;
}


#-------------------------------------------------------------------

=head2 purge ( )

removes collateral data associated with a BuzzCollector when the system
purges it's data.  This method is unnecessary, but if you have 
auxiliary, ancillary, or "collateral" data or files related to your 
wobject instances, you will need to purge them here.

=cut

sub purge {
	my $self = shift;
	#purge your wobject-specific data here.  This does not include fields 
	# you create for your BuzzCollector asset/wobject table.
	return $self->SUPER::purge;
}

#-------------------------------------------------------------------

=head2 view ( )

method called by the www_view method.  Returns a processed template
to be displayed within the page style.  

=cut

sub view {
	my $self = shift;
	my $session = $self->session;	

	#This automatically creates template variables for all of your wobject's properties.
	my $var = $self->get;

    $var->{item_loop} = $self->getItemLoop;
	#This is an example of debugging code to help you diagnose problems.
	#WebGUI::ErrorHandler::warn($self->get("templateId")); 
	
	return $self->processTemplate($var, undef, $self->{_viewTemplate});
}

#-------------------------------------------------------------------

=head2 www_edit ( )

Web facing method which is the default edit page.  This method is entirely
optional.  Take it out unless you specifically want to set a submenu in your
adminConsole views.

=cut

#sub www_edit {
#   my $self = shift;
#   return $self->session->privilege->insufficient() unless $self->canEdit;
#   return $self->session->privilege->locked() unless $self->canEditIfLocked;
#   my $i18n = WebGUI::International->new($self->session, "Asset_BuzzCollector");
#   return $self->getAdminConsole->render($self->getEditForm->print, $i18n->get("edit title"));
#}

#-------------------------------------------------------------------

=head2 www_deleteItem ( )

Deletes an Item.

=cut

sub www_deleteItem {
    my $self        = shift;
    my $session     = $self->session;
    my $itemId      = $session->form->process("itemId");

    return $self->session->privilege->insufficient() unless $self->canEdit;

    $session->db->write("delete from BuzzCollector_item where itemId=?",[$itemId]);
    return $self->www_listItems;
}

#-------------------------------------------------------------------

=head2 www_editItem ( )

Shows a form to edit or add an item. 

=cut

sub www_editItem {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;
    my ($itemId, $item);

    return $session->privilege->insufficient() unless $self->canEdit;
    my $i18n = WebGUI::International->new($session, "Asset_BuzzCollector");

    $itemId = $form->process("itemId") || 'new';

    unless($itemId eq 'new'){
        $item = $self->getItem($itemId);
    }
    my $itemType = $form->process('itemType');

    my $htmlForm = WebGUI::HTMLForm->new($session,-action=>$self->getUrl);
    $htmlForm->hidden(
        -name       =>"func",
        -value      =>"editItemSave"
        );
    $htmlForm->hidden(
        -name       =>"itemId",
        -value      =>$itemId,
        );
    $htmlForm->readOnly(
        -name       =>"itemType",
        -value      =>$itemType,
        -label      =>$i18n->get('itemType label'),
        -hoverHelp  =>$i18n->get('itemType description'),
        );
    # Add item specific form elements.
    my $item = eval { WebGUI::Pluggable::instanciate(
        'WebGUI::Asset::Wobject::BuzzCollector::'.ucfirst($itemType), 'new',[$session,$itemId]) 
    };
    $htmlForm = $item->appendEditScreenFormElements($session,$htmlForm);
    $htmlForm->submit;
    return $self->getAdminConsole->render($htmlForm->print, $i18n->get('edit item title'));
}

#-------------------------------------------------------------------

=head2 www_editItemSave ( )

Shows a form to edit or add an item. 

=cut

sub www_editItemSave {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;
    my ($itemId, $item,$settings);

    return $session->privilege->insufficient() unless $self->canEdit;

    $itemId = $form->process("itemId") || 'new';

    unless($itemId eq 'new'){
        $item = $self->getItem($itemId);
    }

    my $itemType = $item->{itemType} || $form->process('itemType');

    if (WebGUI::Pluggable::instanciate('WebGUI::Asset::Wobject::BuzzCollector::'.ucfirst($itemType), 'hasSettings')) {
        $settings = eval { WebGUI::Pluggable::run(
        'WebGUI::Asset::Wobject::BuzzCollector::'.ucfirst($itemType), 'processSettingsFromFormPost',[$form]) };
    }

    my $itemProperties = {
        itemId          => $itemId,
        buzzCollectorId => $self->getId,
        settings        => $settings,
        itemType        => $itemType,
    };
    $self->setCollateral("BuzzCollector_item","itemId",$itemProperties,0,0);

    return $self->www_listItems;
}

#-------------------------------------------------------------------

=head2 www_listItems ( )

Lists all attributes of this Matrix. 

=cut

sub www_listItems {
    my $self    = shift;
    my $session = $self->session;
    my $output;

    return $session->privilege->insufficient() unless($self->canEdit);

    my $i18n = WebGUI::International->new($session,'Asset_BuzzCollector');

    my $itemTypes = $self->getItemTypes;
    foreach my $itemType (keys %$itemTypes){
        $output .= "<a href='".$self->getUrl("func=editItem;itemId=new;itemType=$itemType")."'>"
                .$i18n->get('add item label')." : ".$itemTypes->{$itemType}."</a><br />";
    }

    my $items = $session->db->read("select * from BuzzCollector_item where buzzCollectorId=?"
        ,[$self->getId]);
    while (my $item = $items->hashRef) {
        my $itemObject = eval { WebGUI::Pluggable::instanciate(
        'WebGUI::Asset::Wobject::BuzzCollector::'.ucfirst($item->{itemType}), 'new',[$session,$item->{itemId}]) };
       
        $output .= $session->icon->delete("func=deleteItem;itemId=".$item->{itemId}.";itemType=".$item->{itemType}
            , $self->getUrl,$i18n->get("delete item confirm message"))
            .$session->icon->edit("func=editItem;itemId=".$item->{itemId}.";itemType=".$item->{itemType})
            .' '.$itemObject->getLabel($session)."<br />\n";
    }
    return $self->getAdminConsole->render($output, $i18n->get('list items title'));
}

#-------------------------------------------------------------------
# Everything below here is to make it easier to install your custom
# wobject, but has nothing to do with wobjects in general
#-------------------------------------------------------------------
# cd /data/WebGUI/lib
# perl -MWebGUI::Asset::Wobject::BuzzCollector -e install www.example.com.conf [ /path/to/WebGUI ]
# 	- or -
# perl -MWebGUI::Asset::Wobject::BuzzCollector -e uninstall www.example.com.conf [ /path/to/WebGUI ]
#-------------------------------------------------------------------


use base 'Exporter';
our @EXPORT = qw(install uninstall);
use WebGUI::Session;

#-------------------------------------------------------------------
sub install {
	my $config = $ARGV[0];
	my $home = $ARGV[1] || "/data/WebGUI";
	die "usage: perl -MWebGUI::Asset::Wobject::BuzzCollector -e install www.example.com.conf\n" unless ($home && $config);
	print "Installing asset.\n";
	my $session = WebGUI::Session->open($home, $config);
	$session->config->addToHash("assets", "WebGUI::Asset::Wobject::BuzzCollector" => { category => 'community' } );
	$session->db->write("create table BuzzCollector (
		assetId char(22) binary not null,
		revisionDate bigint not null,
        templateId char(22) not null,
		primary key (assetId, revisionDate)
		)");
	$session->db->write("create table BuzzCollector_item (
		itemId char(22) binary not null,
		buzzCollectorId char(22) not null,
		iconStorageId char(22),
		settings text,
        itemType char(128) not null,
		primary key (itemId, buzzCollectorId)
		)");
	$session->var->end;
	$session->close;
	print "Done. Please restart Apache.\n";
}

#-------------------------------------------------------------------
sub uninstall {
	my $config = $ARGV[0];
	my $home = $ARGV[1] || "/data/WebGUI";
	die "usage: perl -MWebGUI::Asset::Wobject::BuzzCollector -e uninstall www.example.com.conf\n" unless ($home && $config);
	print "Uninstalling asset.\n";
	my $session = WebGUI::Session->open($home, $config);
	$session->config->deleteFromArray("assets","WebGUI::Asset::Wobject::BuzzCollector");
	my $rs = $session->db->read("select assetId from asset where className='WebGUI::Asset::Wobject::BuzzCollector'");
	while (my ($id) = $rs->array) {
		my $asset = WebGUI::Asset->new($session, $id, "WebGUI::Asset::Wobject::BuzzCollector");
		$asset->purge if defined $asset;
	}
	$session->db->write("drop table BuzzCollector");
	$session->var->end;
	$session->close;
	print "Done. Please restart Apache.\n";
}


1;
#vim:ft=perl
