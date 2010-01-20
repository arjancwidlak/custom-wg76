package WebGUI::Macro::WaskoSearchResults;

use strict;
use WebGUI::Asset;

sub process {
    my $session     = shift;
    my $assetId     = shift;
    my $matchClass  = shift || 'WebGUI::Asset::Wobject::SQLReport';
    my $matchTitle  = 'Lokatie';

    my $asset   = WebGUI::Asset->newByDynamicClass( $session, $assetId );
    return "Could not instanciate asset" unless $asset;
    
    # Als een zoek resultaat een sqlreport is en Lokatie heet dan zoeken we de adresgegevens op.
    if ( $asset->get('className') eq $matchClass && $asset->get('title') =~ /^$matchTitle\s*$/) {
        my $query = q{
            select
               `field_IbYnuRjC5MRW3mNpxZ2RtQ` as Lokatienaam,
               `field_JDeKSK6Vbt-TeK9dqiGZxg` as Adres,
               `field_XJHJLMUupOhtVrnkOpFAfA` as Postcode,
               `field_i9ef0VwdVjQ1h32kPsBzHw` as Plaatsnaam,
               `field_0YgFlGQuOT08Q695xtyh2Q` as Telefoonnummer
            from
               `Thingy_a-L_jtGu8UMujgYpNTtCBg`
            where
               `field_IbYnuRjC5MRW3mNpxZ2RtQ` = ?
        };

        my $address = $session->db->quickHashRef( $query, [ $asset->getContainer->get('title') ] );
        my $output =
            "$address->{Lokatienaam}, $address->{Adres}, $address->{Postcode}, $address->{Plaatsnaam}, "
            ."$address->{Telefoonnummer}, $address->{Opvangsoort}";

        return $output;
    }

    # Zo niet dan geven we de sysnopsis terug, of in geval van geen synopsis, de url.
    my $synopsis = $session->db->quickScalar('select synopsis from assetIndex where assetId=?', [ $assetId ]);
    return $synopsis || $asset->get('url');
}

1;

