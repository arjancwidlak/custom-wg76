package WebGUI::Asset::Wobject::NoteDropper;

$VERSION = "0.1.0";

use strict;
use Tie::IxHash;
use WebGUI::International;
use WebGUI::Utility;
use WebGUI::Asset::Wobject::NoteDropper::Note;
use WebGUI::Paginator;
use JSON qw{ from_json to_json };
use Data::Dumper;

use base 'WebGUI::Asset::Wobject';

sub stripFormElement {
    my $self    = shift;
    my $element = shift;

    $element    =~ s{(style|id)="[^"]+"}{}gxms;

    return $element;
}

#-------------------------------------------------------------------
sub appendPostFormVars {
    my $self    = shift;
    my $var     = shift || {};
    my $values  = shift || {};
    my $session = $self->session;
    my $i18n    = WebGUI::International->new( $session, 'NoteDropper' );

    my $maxCharacters = $self->get('maxContentLength');
    my $contentExtras =
        qq| onkeyup="if (this.textLength > $maxCharacters) { this.value=this.previousValue }" |
        . qq| onkeydown="this.previousValue = this.value" |;
    $contentExtras = '' unless $maxCharacters;

    my $noteId = $values->{ noteId } || 'new';

    $var->{ form_header     } = 
        WebGUI::Form::formHeader( $session, { action => $self->getUrl } )
        . WebGUI::Form::hidden( $session, { name => 'func',     value => 'editNoteSave' } )
        . WebGUI::Form::hidden( $session, { name => 'noteId',   value => $noteId        } );
    $var->{ form_footer         } = WebGUI::Form::formFooter( $session );
    $var->{ form_title          } = WebGUI::Form::text( $session, { name => 'title', value => $values->{ title } } );
    $var->{ form_title_plain    } = $self->stripFormElement( $var->{ form_title } );
    $var->{ form_title_value    } = $values->{ title };

    $var->{ form_content_value  } = $values->{ content };
    $var->{ form_content        } = 
        WebGUI::Form::textarea( $session, { 
            name        => 'content',
            value       => $values->{ content }, 
            extras      => $contentExtras,
            resizable   => 0,
        } );
    $var->{ form_content_plain  } = $self->stripFormElement( $var->{ form_content } );
    $var->{ form_content_html   } = WebGUI::Form::HTMLArea( $session, { name => 'content', extras => $contentExtras }, value => $values->{ content } );
    $var->{ form_submit         } = WebGUI::Form::submit( $session, { value => $i18n->get('add') } );

    for my $num (1..5) {
        for my $type ( qw{ text url textarea HTMLArea } ) { #textarea HTMLArea url } ) {
            my $element = 
                WebGUI::Form::dynamicField( $session,  
                    name        => "userDefined$num", 
                    value       => $values->{ "userDefined$num" },
                    fieldType   => $type,
                    resizable   => 0,
                );
            my $key = "form_userDefined$num". '_' . lc $type;

            $var->{ $key            } = $element;
            $var->{ $key . "_plain" } = $self->stripFormElement( $element )
        }
        $var->{ "form_userDefined$num"."_value" } = $values->{ "userDefined$num" };
    }

    return $var;
}

#-------------------------------------------------------------------
sub canDeleteNote {
    my $self    = shift;
    my $note    = shift;
    my $user    = shift || $self->session->user;

    return $user->isInGroup( $self->get('moderatorGroupId') );
}   

#-------------------------------------------------------------------
sub canEditNote {
    my $self    = shift;
    my $note    = shift;
    my $user    = shift || $self->session->user;

    return $user->userId eq $note->get('userId') 
        || $user->isInGroup( $self->get('moderatorGroupId') );
}

#-------------------------------------------------------------------
sub canPostNote {
    my $self = shift;

    return $self->session->user->isInGroup( $self->get('postGroupId') );
}

#-------------------------------------------------------------------
sub canRateNote {
    my $self    = shift;
    my $note    = shift;
    my $user    = shift || $self->session->user;
    my $db      = $self->session->db;

    # Authors cannot rate their own notes.
    return 0 if $note->get('userId') eq $user->userId;

    # Only users in rate group can rate.
    return 0 unless $user->isInGroup( $self->get('rateGroupId') );

    # For now, let visitors vote indefinitely if they are in the rate group.
#    return 1;

    # Users can only vote once.
    my $hasVoted = $db->quickScalar( 'select 1 from NoteDropper_votes where noteId=? and ( userId=? || sessionId=? )', [
        $note->getId,
        $user->userId,
        $self->session->getId,
    ] );
    return 0 if $hasVoted;

    return 1;
}

#-------------------------------------------------------------------
sub definition {
    my $class      = shift;
    my $session    = shift;
    my $definition = shift;
#    my $i18n       = WebGUI::International->new( $session, 'Asset_NewWobject' );
    tie my %properties, 'Tie::IxHash', (
        noteCount => {
            noFormPost      => 1,
            fieldType       => 'hidden',
            defaultValue    => 0,
        },
        totalRating => {
            noFormPost      => 1,
            fieldType       => 'hidden',
            default         => 0,
        },
        returnToContainerAsset => {
            fieldType       => 'yesNo',
            label           => 'Disable asset view',
            defaultValue    => 0,
            tab             => 'display',
        },
        postGroupId => {
            fieldType       => 'group',
            label           => 'Who can post notes',
            tab             => 'security',
        },
        moderatorGroupId => {
            fieldType       => 'group',
            label           => 'Who can moderate notes',
            tab             => 'security',
        },
        rateGroupId => {
            fieldType       => 'group',
            label           => 'Who can rate notes',
            tab             => 'security',
        },
        templateId => {
            fieldType       => 'template',
            label           => 'Template',
            tab             => 'display',
            namespace       => 'NoteDropper',
        },
        manageNotesTemplateId => {
            fieldType       => 'template',
            label           => 'Note manager template',
            tab             => 'display',
            namespace       => 'NoteDropper/Manage',
        },
        postFormTemplateId => {
            fieldType       => 'template',
            label           => 'Post form template',
            tab             => 'display',
            namespace       => 'NoteDropper/PostForm',
        },
        maxContentLength => {
            fieldType       => 'integer',
            label           => 'Max content length',
            tab             => 'display',
        },
        notesPerPage => {
            fieldType       => 'integer',
            label           => 'Notes per page',
            tab             => 'display',
            defaultValue    => 0,
        },
        positiveScore => {
            fieldType       => 'integer',
            label           => 'Positive vote score',
            tab             => 'properties',
            defaultValue    => 1,
        },
        neutralScore => {
            fieldType       => 'integer',
            label           => 'Neutral vote score',
            tab             => 'properties',
            defaultValue    => 0,
        },
        negativeScore => {
            fieldType       => 'integer',
            label           => 'Negative vote score',
            tab             => 'properties',
            defaultValue    => -1,
        },
    );

    my $sortOptions = $class->getSortOptions( $session ); 

    for (1..5) {
        $properties{ "sortBy$_" } = {
            fieldType   => 'selectBox',
            label       => "Sort criterion $_",
            tab         => 'display',
            options     => $sortOptions,
        };
        $properties{ "sortAsc$_" } = {
            fieldType   => 'radioList',
            label       => "Sort criterion $_ sort direction",
            tab         => 'display',
            options     => { '1' => 'Ascending', 0 => 'Descending' },
        };
    }

    push @{$definition}, {
        assetName         => 'NoteDropper', #$i18n->get('assetName'),
#        icon              => 'newWobject.gif',
        autoGenerateForms => 1,
        tableName         => 'NoteDropper',
        className         => 'WebGUI::Asset::Wobject::NoteDropper',
        properties        => \%properties
    };

    return $class->SUPER::definition( $session, $definition );
} ## end sub definition

#-------------------------------------------------------------------
sub getNotesPaginator {
    my $self            = shift;
    my $notesPerPage    = shift || $self->getValue( 'notesPerPage' );
    my $session         = $self->session;
    my ($db, $form)     = $session->quick( qw{ db form } );

    #---- Setup note selection criteria. ----
    my $noteOnTop = $session->stow->get( "noteOnTop_".$self->getId );
    my $dbUserId  = $db->quote( $session->user->userId );

    # Build sorting order
    my @order;
    push @order, 'NoteDropper_notes.noteId <> ' . $db->quote( $noteOnTop ) if $noteOnTop;

    # Make sure search state is resettable.
    if ( defined $form->process( 'sortBy' ) && !$form->process( 'sortBy' ) ) {
        $self->setState( 'sortBy', undef );
        $self->setState( 'sortDirection', undef );
    }

    if ( $form->process( 'sortBy' ) =~ /^([A-Za-z0-9_]+?)(?:_(asc|desc))?$/ ) {
        my $field       = $1;
        my $direction   = $2 || 'asc';
        
        if ( isIn( $field, keys %{ $self->getSortOptions( $session ) } ) ) {
            push @order, "$field $direction";
        }

        $self->setState( 'sortBy', $field );
        $self->setState( 'sortDirection', $direction );

#        $var->{ "sortBy_$field" } = 1;
    }
    elsif ( $self->getState( 'sortBy' ) ) {
        my $field       = $self->getState( 'sortBy' );
        my $direction   = $self->getState( 'sortDirection' ) || 'asc';

        push @order, "$field $direction";

#        $var->{ "sortBy_$field" } = 1;
    }
    else {
        for (1..5) {
            my $direction = $self->get( "sortAsc$_" ) ? 'asc' : 'desc';

            if ( $self->get("sortBy$_") eq 'canVote') {
                push @order, "(NoteDropper_notes.userId <> $dbUserId and vote is null) $direction";
            }
            elsif ( $self->get("sortBy$_") eq 'random') {
                push @order, 'rand()';
            }
            elsif ( $self->get("sortBy$_") ) {
                push @order, 'NoteDropper_notes.' . $self->get("sortBy$_") . " $direction";
            }
        }

#        $var->{ sortBy_default } = 1;
    }

    # Build search constraints.
    my $constraints;
    $constraints->{ 'join'      } = [  
        "NoteDropper_votes on "
            . " NoteDropper_notes.noteId=NoteDropper_votes.noteId "
            . " and NoteDropper_votes.userId=$dbUserId ",
    ];
    $constraints->{ orderBy     } = join( ', ', @order ) if @order;
    $constraints->{ constraints } = [ { 'assetId = ?', [ $self->getId ] } ];


    # Fetch notes
    my $p = WebGUI::Paginator->new( $session, $self->getUrl, $notesPerPage );

    my ($query, $placeholders) = WebGUI::Asset::Wobject::NoteDropper::Note->getAllSql( $session, $constraints );
    $p->setDataByQuery( $query, undef, 0, $placeholders  );

    return $p;
}

#-------------------------------------------------------------------
sub getSortOptions {
    my $class   = shift;
    my $session = shift;

    tie my %sortOptions, 'Tie::IxHash', ( 
        '' => '---',
        map     { $_ => "Field $_" } 
        sort
        keys    %{ WebGUI::Asset::Wobject::NoteDropper::Note->crud_definition( $session )->{ properties } }
    );

    $sortOptions{ random            } = 'Random';
    $sortOptions{ canVote           } = 'Can vote';
    $sortOptions{ sequenceNumber    } = 'Sequence number';
    $sortOptions{ dateCreated       } = 'Date created';
    $sortOptions{ dateUpdated       } = 'Date updated';

    return \%sortOptions;
}

#-------------------------------------------------------------------
sub getState {
    my $self = shift;
    my $key  = shift;
    my $scratch = $self->session->scratch;

    unless (defined $self->{ _state } ) {
        $self->{ _state } = from_json( $scratch->get( $self->getId . '_state' ) || '{}' );
    }

    return $self->{ _state }->{ $key } if $key;
    return { %{ $self->{ _state } } };
}

#-------------------------------------------------------------------
sub getViewVars {
    my $self    = shift;
    my $session = $self->session;
    my ( $db, $form, $url ) = $session->quick( qw{ db form url } );

    # Asset properties
    my $var     = $self->get;

    my $p = $self->getNotesPaginator;
    $p->appendTemplateVars( $var );

    my @noteLoop;
    foreach my $data ( @{ $p->getPageData } ) {
        my $note = WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $data->{ noteId } );
        push @noteLoop, $self->getNoteVars( $note );
    }

    my $sortField = $self->getState( 'sortBy' ) || 'default';
    $var->{ "sortBy_$sortField" } = 1;
    $var->{ note_loop           } = \@noteLoop;
    $var->{ addNote_url         } = $self->getUrl('func=editNote;noteId=new');
    $var->{ user_canPost        } = $session->user->isInGroup( $self->get('postGroupId') );

    # Add in form vars
    $self->appendPostFormVars( $var );

    return $var;
}

#-------------------------------------------------------------------
sub getNoteVars {
    my $self    = shift;
    my $note    = shift;
    my $session = $self->session;

    my $poster  = WebGUI::User->new( $session, $note->get('userId') );
   
    my $noteVar = $note->get;
    $noteVar->{ edit_url        } = $self->getUrl('func=editNote;noteId='.$note->getId);
    $noteVar->{ delete_url      } = $self->getUrl('func=deleteNote;noteId='.$note->getId);
    $noteVar->{ rate_url        } = $self->getUrl('func=rateNote;noteId='.$note->getId);
    $noteVar->{ user_canRate    } = $self->canRateNote( $note );
    $noteVar->{ user_canEdit    } = $self->canEditNote( $note );
    $noteVar->{ user_canDelete  } = $self->canDeleteNote( $note );
    $noteVar->{ user_isVisitor  } = $session->user->userId eq '1';

    if ( $poster ) {
        $noteVar->{ poster_username    } = $poster->username;
        $noteVar->{ poster_fullname    } = 
            join ' ', map { $poster->profileField( $_ ) } qw{ firstName middleName lastName };
        $noteVar->{ poster_profile_url } = $session->url->page('op=viewProfile;uid=' . $poster->userId );
    };   

    return $noteVar;
};

#-------------------------------------------------------------------
sub prepareView {
	my $self = shift;
	$self->SUPER::prepareView();
	my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
	$template->prepare;
	$self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------
sub purge {
    my $self = shift;

    #purge your wobject-specific data here.  This does not include fields
    # you create for your NewWobject asset/wobject table.
    return $self->SUPER::purge;
}

#-------------------------------------------------------------------
sub view {
    my $self    = shift;
    my $session = $self->session;

    my $var = $self->getViewVars;
    
    if ($self->get('returnToContainerAsset') ) {
        $session->http->setRedirect( $self->getParent->getUrl );
    }

    return $self->processTemplate( $var, undef, $self->{_viewTemplate} );
}

#-------------------------------------------------------------------
sub setState {
    my $self    = shift;
    my $key     = shift;
    my $value   = shift;
    my $scratch = $self->session->scratch;

    my $state   = $self->{ _state }; 
    $state->{ $key } = $value;
    $self->{ _state } = $state;

    $scratch->set( $self->getId . '_state', to_json( $state ) );
}

#-------------------------------------------------------------------
sub updateStatistics {
    my $self    = shift;
    my $db      = $self->session->db;

    my $totalRating = $db->quickScalar( 'select sum(rating) from NoteDropper_notes where assetId=?', [
         $self->getId,
    ] );
    my $totalNotes  = $db->quickScalar( 'select count(*) from NoteDropper_notes where assetId=?', [
        $self->getId,
    ] );
    $self->update( { 
        totalRating => $totalRating,
        noteCount   => $totalNotes,
    } );
}

#-------------------------------------------------------------------
sub www_editNote {
    my $self        = shift;
    my $session     = $self->session;
    my $privilege   = $session->privilege;
    my $noteId      = $session->form->process( 'noteId' );

    my $properties = {};
    if ($noteId ne 'new') {
        my $note = WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $noteId );
        return 'error: invalid note id' unless $note;

        return $privilege->insufficient unless $self->canEditNote( $note );

        $properties = $note->get;
    }
    else {
        return $privilege->insufficient unless $self->canPostNote; 
    }

    my $var = $self->appendPostFormVars( {}, $properties );
    
    my $template = WebGUI::Asset::Template->new( $session, $self->get('postFormTemplateId') );

    return $self->processStyle( $template->process( $var ) );
}

#-------------------------------------------------------------------
sub www_deleteNote {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;

    my $noteId  = $form->process( 'noteId' );
    my $note    = WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $noteId );
    return "invalid note id [$noteId]" unless $note;

    return $session->privilege->insufficient unless $self->canDeleteNote( $note );

    $note->delete;
    $self->updateStatistics;

    if ( $form->process('proceed') eq 'manageNotes' ) {
        return $self->www_manageNotes;
    }

    return $self->www_view;
}

#-------------------------------------------------------------------
sub www_editNoteSave {
    my $self    = shift;
    my $session = $self->session;
    my $form    = $session->form;
    my $noteId  = $session->form->process( 'noteId' );

    # Check if note is new and user is allowed to post it.
    return $session->privilege->insufficient if $noteId eq 'new' && !$self->canPostNote;

    # require a non-empty post.
    return $self->www_view unless $form->process( 'title' ) || $form->process( 'content' );

    my $note    = $noteId eq 'new'
                ? WebGUI::Asset::Wobject::NoteDropper::Note->create( $session )
                : WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $noteId )
                ;
    return "invalid note id [$noteId]" unless $note;

    # Check if note is editable by user.
    return $session->privilege->insufficient unless $noteId eq 'new' || $self->canEditNote( $note );

    $note->updateFromFormPost;
    $note->update( { assetId => $self->getId } );
    
    if ( $noteId eq 'new' ) {
        $note->update( { userId  => $session->user->userId } );
        $self->updateStatistics;
    }

    $session->stow->set( "noteOnTop_".$self->getId, $note->getId );

    if ( $form->process('responseType') eq 'json' ) {
        $session->http->setMimeType( 'application/json' );
        return to_json( $self->getNoteVars( $note ) );
    }
    if ( $form->process('proceed') eq 'manageNotes' ) {
        return $self->www_manageNotes;
    }

    return $self->www_view;
}

#-------------------------------------------------------------------
sub www_getNotesAsJSON {
    my $self    = shift;
    my $session = $self->session;

    $session->http->setMimeType( 'application/json' );

    return '{}' unless $self->canView;

    my $noteId = $session->form->process('noteId');
    if ( $noteId ) {
        my $note = WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $noteId );
        return '{}' unless $noteId;

        my $var = $self->getNoteVars( $note );
        return to_json( $var );
    }
    else {
        my @noteLoop;
        my $p = $self->getNotesPaginator( 9999999 );
        foreach my $data ( @{ $p->getPageData } ) {
            my $note = WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $data->{ noteId } );
            push @noteLoop, $self->getNoteVars( $note );
        }

        return to_json( \@noteLoop );
    }
}

#-------------------------------------------------------------------
sub www_rateNote {
    my $self    = shift;
    my $session = $self->session;

    my $noteId  = $session->form->process( 'noteId' );
    my $score   = int $session->form->process( 'vote'   );
    $score      = 
        $score >= 1     ? $self->getValue('positiveScore')  :    
        $score == 0     ? $self->getValue('neutralScore')   :
        $score <= -1    ? $self->getValue('negativeScore')  :
                        return "Illegal rating [$score]";

    my $note = WebGUI::Asset::Wobject::NoteDropper::Note->new( $session, $noteId ) || return 'invalid noteId';

    if ($self->canRateNote( $note ) ) {
        $note->update( { rating => $note->get('rating') + $score } );

        $session->db->write('insert into NoteDropper_votes (noteId, userId, vote, sessionId) values (?,?,?,?)', [
            $note->getId,
            $session->user->userId,
            $score,
            $session->user->userId eq '1' ? $session->getId : '',
        ] );
        
        $self->updateStatistics;
    }

    return $self->www_view;
}

sub www_manageNotes {
    my $self    = shift;
    my $session = $self->session;

    my $var = $self->getViewVars;
    my $template = WebGUI::Asset::Template->new( $session, $self->get('manageNotesTemplateId') );

    return $self->processStyle( $template->process( $var ) );
}


sub www_view {
    my $self    = shift;
    my $session = $self->session;

    my ($form, $stow) = $session->quick( qw{ form stow } );

    if ( !$stow->get( 'shortcutProcessed' ) && $form->process('useShortcutId') ) {
        $stow->set( 'shortcutProcessed', 1 );
        my $shortcut = WebGUI::Asset::Shortcut->new( $session, $form->process('useShortcutId') );

        return $self->SUPER::www_view unless defined $shortcut;
        return $self->SUPER::www_view unless $shortcut->isa( 'WebGUI::Asset::Shortcut' );
        return $self->SUPER::www_view unless $shortcut->get( 'shortcutToAssetId' ) eq $self->getId;
        
        return $shortcut->www_view;
    }

    return $self->SUPER::www_view;
}

1;

#vim:ft=perl
