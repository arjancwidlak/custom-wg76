package WebGUI::Macro::PostForm;

use strict;

use WebGUI::Asset;

=head1 NAME

WebGUI::Macro::PostForm

=head1 DESCRIPTION

Returns the form used by the collaboration system to post a reply to or create a new thread or post.

=head1 USAGE

    ^PostForm(id);

=head2 id

The asset id of either the Collaboration System, Thread or Post the reply is for.

=cut

sub process {
    my $session = shift;
    my $id      = shift;

    my $parent  = WebGUI::Asset->newByDynamicClass( $session, $id );

    my $parentClass = $parent->get('className');
    my $replyClass
        = $parentClass =~ m{^WebGUI::Asset::Wobject::Collaboration}   ? 'WebGUI::Asset::Post::Thread'
        : $parentClass =~ m{^WebGUI::Asset::Post}                     ? 'WebGUI::Asset::Post'
        : return "Cannot reply to asset of class: $parentClass"
        ;
    
    my $replyProperties = {
        className                   => $replyClass,
        parentId                    => $parent->getId,
        groupIdView                 => $parent->get("groupIdView"),
        groupIdEdit                 => $parent->get("groupIdEdit"),
        ownerUserId                 => $parent->get("ownerUserId"),
        encryptPage                 => $parent->get("encryptPage"),
        styleTemplateId             => $parent->get("styleTemplateId"),
        printableStyleTemplateId    => $parent->get("printableStyleTemplateId"),
        isHidden                    => 1,
        assetId                     => 'new',
    };

    my $reply = WebGUI::Asset->newByPropertyHashRef( $session, $replyProperties );
    $reply->{_parent} = $parent;
   
    # Since WG::A::Post->www_edit relies on some form vars being set we override the default behaviour of
    # WG::S::Form->process to give the desired results.
    my $process = *{ WebGUI::Session::Form::process }{ CODE };
    local *{ WebGUI::Session::Form::process } = sub {
        my $self = shift;

        # Our overrides
        return 'add'        if $_[0] eq 'func';
        return $replyClass  if $_[0] eq 'class';

        # Otherwise default to the original sub.
        return $self->$process( @_ );
    };

    # We don't want the sobject style wrapped around our precious content.
    local *{ WebGUI::Asset::Wobject::Collaboration::processStyle } = sub { return $_[1] };
    local *WebGUI::Session::Style::sent = sub { return 0 }; 
    
    return undef unless $reply->canEdit;
 
    return $reply->www_edit();
}

1;

