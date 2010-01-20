package WebGUI::Macro::ThreadView;

use strict;

use WebGUI::Asset;

=head1 NAME

WebGUI::Macro::ThreadView

=head1 DESCRIPTION

Returns the thread view of a given post or thread.

=head1 USAGE

    ^ThreadView(id);

=head2 id

The id of the thread or post of whcih the tread view should be returned.

=cut

sub process {
    my $session     = shift;
    my $id          = shift;
    my $templateId  = shift;

    my $asset = WebGUI::Asset->newByDynamicClass( $session, $id );

    $templateId ||= $asset->getThread->getParent->get('threadTemplateId');

    if ($asset->canView) {
        local *{ WebGUI::Asset::Wobject::Collaboration::get } = sub {
            my $self = shift;

            return $templateId if $_[0] eq 'threadTemplateId';
            return $self->WebGUI::Asset::Wobject::get( @_ );
        };

        $asset->prepareView;
        return $asset->view;
    }

    return undef;
}

1;

