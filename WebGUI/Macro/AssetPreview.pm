package WebGUI::Macro::AssetPreview;

use strict;

use WebGUI::Asset;
use WebGUI::HTML;
use Text::Wrap;

sub process {
    my $session     = shift;
    my $assetId     = shift || return 'AssetId required.';
    my $property    = shift || return 'Property required.';
    my $count       = shift || return 'Character count required';

    my $asset = WebGUI::Asset->newByDynamicClass( $session, $assetId );
    return 'Invalid assetId' unless $asset;

    # Get property and strip all html.
    my $text = WebGUI::HTML::filter( $asset->get( $property ), 'all');
    $text =~ s{^\s+}{}xms;
    $text =~ s{\s+}{ }gxms;

    # Set desired content lengnth.
    local $Text::Wrap::columns  = $count + 1;
#    local $Text::Wrap::huge     = 'overflow';

    # Wrap the text to the desired length and return only the first line.
    my @lines = split /\n/, wrap('', '', $text);
    return $lines[0] || $lines[1];
}

1;

