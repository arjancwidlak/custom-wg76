package WebGUI::Asset::Wobject::DataForm::RoutedQuestions;

use strict;

use Data::Dumper;
use List::Util qw{ shuffle first };
use JSON qw{ to_json from_json };

use base qw{ WebGUI::Asset::Wobject::DataForm };

sub definition {
    my $class       = shift;
    my $session     = shift;
    my $definition  = shift || [];

    my %properties = (
        tabRouting => {
            fieldType       => 'radioList',
            label           => 'Tab routing',
            options         => { seq => 'Sequential', rnd => 'Random' },
            defaultValue    => 'seq',
        },
    );

    push @{ $definition }, {
        assetName           => 'RoutedQuestions',
        tableName           => 'RoutedQuestions',
        className           => 'WebGUI::Asset::Wobject::DataForm::RoutedQuestions',
        properties          => \%properties,
        autoGenerateForms   => 1,
    };

    return $class->SUPER::definition( $session, $definition );
}

sub getRoute {
    my $self        = shift;
    my $ordering    = shift || $self->get('tabRouting');
    my $scratch     = $self->session->scratch;

    my $id = $self->getId;
    my $route = from_json( $scratch->get( "route_$id" ) || '{}' );
    unless (%{ $route }) {
        my @tabOrder    = @{ $self->getTabOrder };
        @tabOrder       = shuffle @tabOrder if $ordering eq 'rnd';

        $route->{ tabOrder      } = \@tabOrder;
        $route->{ currentTab    } = 0;

        $scratch->set( "route_$id", to_json( $route ) );
    }

    return $route;
}

sub getTabByAssetLink {
    my $self    = shift;
    my $assetId = shift;

    my @tabs = grep { $_->{assetLink} eq $assetId } values %{ $self->getTabConfig };

    return $tabs[0];
}

sub getTabByLastCompleted {
    my $self    = shift;

    my $tabId   = first { $self->tabComplete( $_ ) } reverse @{ $self->getRoute->{ tabOrder} };
    
    return $self->getTabConfig( $tabId || $self->getRoute->{tabOrder}->[0] );
}

#-------------------------------------------------------------------
sub getUserEntry {
    my $self    = shift;
    my $userId  = shift || $self->session->user->userId;
    my $db      = $self->session->db;

    # Figure out the id of the entry belonging to the given user.
    my $entryId = $db->quickScalar( 'select DataForm_entryId from DataForm_entry where userId=? and assetId=?', [
        $userId,
        $self->getId,
    ] );

#    # No entry yet for this user, so return undef.
#    return undef unless $entryId;

    # User has an entry, so let's return that.
    return $self->entryClass->new( $self, $entryId );
}

sub getTabFields {
    my $self    = shift;
    my $tabId   = shift;
    
    my @fields = 
        grep    { $_->{tabId} eq $tabId }
        map     { $self->getFieldConfig( $_ ) }
                @{ $self->getFieldOrder };

    return \@fields;
}

sub tabComplete {
    my $self    = shift;
    my $tabId   = shift;
    my $user    = shift || $self->session->user;

    # Get the data entered by the user. If there is none the tab cannot possibly be complete so bail out.
    my $entry   = $self->getUserEntry( $user->userId );
    return 0 unless $entry;

    # Get the field config for the field tied to this tab.
    my @fields = @{ $self->getTabFields( $tabId ) };

    for my $field ( @fields ) {
        my $fieldValue = $entry->field( $field->{name} );
        return 1 if defined $fieldValue && $fieldValue ne q{};
    }

    return 0;
}

#-------------------------------------------------------------------
sub www_editTab {
    my $self = shift;
    return $self->session->privilege->insufficient
        unless $self->canEdit;
    my $i18n = WebGUI::International->new($self->session,"Asset_DataForm");
    my $tabId = shift || $self->session->form->process("tabId") || "new";
    my $tab;
    unless ($tabId eq "new") {
        $tab = $self->getTabConfig($tabId);
    }

    my $f = WebGUI::HTMLForm->new($self->session,-action=>$self->getUrl);
    $f->hidden(
        name    => "tabId",
        value   => $tabId,
    );
    $f->hidden(
        name   => "func",
        value  => "editTabSave",
    );
    $f->text(
        name    => "label",
        label   => $i18n->get(101),
        value   => $tab->{label},
    );
    $f->textarea(
        name    => "subtext",
        label   => $i18n->get(79),
        value   => $tab->{subtext},
    );
    $f->HTMLArea(
        name    => 'description',
        label   => 'Description',
        value   => $tab->{ description },
    );
    $f->asset(
        name    => 'assetLink',
        label   => 'Link to asset',
        value   => $tab->{ assetLink },
        class   => 'WebGUI::Asset::Wobject::Layout',
    );
    $f->asset(
        name    => 'redirectAfterSave',
        label   => 'Redirect after save',
        value   => $tab->{ redirectAfterSave },
        class   => 'WebGUI::Asset::Wobject::Layout',
    );
    if ($tabId eq "new") {
        $f->whatNext(
            options=>{
                editTab=>$i18n->get(103),
                ""=>$i18n->get(745)
            },
            -value=>"editTab"
        );
    }
    $f->submit;
    my $ac = $self->getAdminConsole;
    return $ac->render($f->print,$i18n->get('103')) if $tabId eq "new";
    return $ac->render($f->print,$i18n->get('102'));
}

sub www_editTabSave {
    my $self = shift;
    my $form = $self->session->form;

    my $output = $self->SUPER::www_editTabSave;

    my $tabId   = $form->process( 'tabId' );
    $tabId      = $self->getTabOrder->[ -1 ] if $tabId eq 'new';
    my $tab     = $self->getTabConfig( $tabId );

    $tab->{ description         } = $form->process( 'description'       );
    $tab->{ assetLink           } = $form->process( 'assetLink'         );
    $tab->{ redirectAfterSave   } = $form->process( 'redirectAfterSave' );

    $self->_saveTabConfig;

    return $output;
}

sub www_processTabData {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;

    my @tabIds  = $form->process( 'tabId' );
    my $entry   = $self->getUserEntry;

    foreach my $tabId ( @tabIds ) {
        next if $self->tabComplete( $tabId );

        my $fields  = $self->getTabFields( $tabId );
        foreach my $field ( @{ $fields } ) {
            my $value = $form->process( $field->{name}, $field->{type}, $field->{defaultValue} );

            $entry->field( $field->{name}, $value );
        }
    }

    $entry->save;

    my $tab = $self->getTabConfig( @tabIds[0] );
    if ( $tab->{ redirectAfterSave } ) {
        my $asset = WebGUI::Asset->newByDynamicClass( $session, $tab->{ redirectAfterSave } );

        $session->http->setRedirect( $asset->getUrl );
        return 'saved';
    }

    return 'saved';
}

1;


