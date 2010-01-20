package WebGUI::Macro::GoogleMaps;

use strict;
use LWP::Simple;
use XML::Simple;
use WebGUI::Cache;
use Data::Dumper;

=head1 NAME

WebGUI::Macro::GoogleMaps

=head1 DESCRIPTION

The GoogleMaps macro allows you to display a google maps map containing markers
at the addresses in an address list. Clicking on the markers opens a templatable
popup infoc 'cloud'. Additionally a side bar can be displayed containing the
entries, clicking on which pan the maps to the address associated with that
entry and opens its info 'cloud'.

The address list can be the users in a WebGUI group or an XML file containing
addresses. In the former case addresses are extracted from the users profile.
Finally it is possible to display just one marker poniting to an address entered
in the parameters of the macro. It is possible to display just one address
entered directly in the macros parameters. In that case usage of info clouds and
sidebar is disabled.

=head1 USAGE

Before you can do anything you'll need a Google Maps API Key for your domain. You can obtain one here:

    http://www.google.com/apis/maps/signup.html

^GoogleMaps(group=3,showSidebar=1,key=YOURKEYHERE);

^GoogleMaps(xml=http://example.com/addresses.xml,xmlContainer=person,addressComposition=fullAddress;country,nameComposition=name);

^GoogleMaps("address=Rotterdamseweg 183c Delft Nederland",key=YOURKEYHERE);

=head1 PARAMETERS

NOTE: Either xml, group or address are required and they are mutually exclusive.
This means that you can only use on of them. The key is required too, but can
also be put in the config file.

=head2 xml
    The data source is an xml file. The value should be the url to this file.
    ie. "xml=http://example.com/myAddresses.xml"

=head2 group
    The data source is a WebGUI group. The value should be the id of the group.
    ie. "group=3"  (All admins).

=head2 address
    The macro displays just one address. The value should be the address.
    ie. "address=Rotterdamse weg 183c Delft Nederland" (Oqapi HQ)

=head2 key
    The Google Maps API key for your domain. You can also put this key in your
    webgui configuration file. To do that add an entry called
    "googleMapsApiKey". If you do that you can skip this option.  ie.
    "key=ABQIAAAA6N24ruKdelIxRFPdrXxPBRSbgCKulLifscvmfKz18hFXjKDCzhSBA9LoumpbK2Rw1udOLBKe__MC"

=head2 xmlContainer
    The container in which each entry resides. Defaults to 'item'.

=head2 addressComposition
    The fieldnames of the fields in your data source that comprise an address
    understandable by the Google geocoder. Seperate fields with a semi colon.
    ie. "addressComposition=street;number;zip;city"

    Defaults to 'homeAddress;homeZip;homeCity;homeState;homeCountry' for a group
    datasources.  Defaults to 'address;zip;city;state;country' for an xml data
    source.

=head2 infoBoxTemplate
    The id of the template for the info 'cloud'. Defaults to the default
    template, see below.

=head2 showSidebar
    Set this value to 1 in order to show the sidebar. Defaults to no sidebar.

=head2 nameComposition
    The composition of names in the sidebar. See addressComposition for syntax.
    Defaults to 'firstName;middleName;lastName'.

=head2 width
    The width of the map in pixels. Defaults to 500.

=head2 height
    The height of the map in pixels. Defaults to 300.

=head1 TEMPLATES

The GoogleMaps macro allows you to template the info 'cloud', and that is
probably what you want to do anyway. If you don't, the following templates are
used as a default.

For a webgui group data source:
    <b><i><tmpl_var firstName> <tmpl_var middleName> <lastName></i></b><br />
    <tmpl_var homeAddress><br />
    <tmpl_var homeZip> <tmpl_var homeCity>

    The available tmpl_vars are the visible profile fields.

For a xml data source:
    <b><i><tmpl_var name></i></b><br />
    <tmpl_var address><br />
    <tmpl_var zip> <tmpl_var city>

    The avilable tmpl_vars are the xml tags that are in the container.

=head1 CAVEATS

This macro does not scale very well with very long lists of addresses. For each
address a request is done to the google geocoder, therefore a lot of addresses
will cause a long page load. To overcome this problem geocoded addresses are
cached. This cache exists for a day and is shared amongst all GoogleMaps macros
on your site. If the cache expires you will see a slow pageload again (in case
of many addresses). Subsequent page loads should be substantially faster.

Addresses that do not geocode correctly are silently skipped, so if you mis
someone check if their address is comprehensible =).

=head1 AUTHOR

The GoogleMaps macro copyright 2007 by Martin Kamerbeek

=head1 LICENCE

The GoogleMaps macro is licenced GPL v2 and may be distributed under its terms.

The GPL v2 licence can be obtained at http://www.gnu.org/licenses/gpl.html

=cut

my $groupsTemplate = <<EOT;
<b><i><tmpl_var firstName> <tmpl_var middleName> <tmpl_var lastName></i></b><br />
<tmpl_var homeAddress><br />
<tmpl_var homeZip> <tmpl_var homeCity>
EOT

my $xmlTemplate = <<EOT;
<b><i><tmpl_var name></i></b><br />
<tmpl_var address><br />
<tmpl_var zip> <tmpl_var city>
EOT

#-------------------------------------------------------------------
sub getDataFromGroup {
    my (@data);
    my $session = shift;
    my $groupId = shift;

    my @profileFields;
    foreach my $field (@{WebGUI::ProfileField->getFields($session)}) {
        push (@profileFields, $field->getId); # if ($field->isViewable);
    }

    my $group = WebGUI::Group->new($session, $groupId);
    foreach my $userId (@{$group->getUsers}) {
        my $user = WebGUI::User->new($session, $userId);
        
        my %userData;
        foreach my $field (@profileFields) {
            $userData{$field} = $user->profileField($field);
        }

        push (@data, { %userData });
    }

    return \@data;
}

#-------------------------------------------------------------------
sub getDataFromXML {
    my ($data);
    my $session     = shift;
    my $url         = shift;
    my $container   = shift || 'item';

    my $xml = get($url);
    $xml =~ s/[\n\r]//g;

    my $data = XMLin($xml, 
        KeyAttr         => '',
        SuppressEmpty   => 1,
    );

    return $data->{$container};
}

#-------------------------------------------------------------------
sub geocodeAddress {
    my $session = shift;
    my $address = shift;
    my $key = shift;

    my $uri = URI->new("http://maps.google.com/maps/geo");
    $uri->query_form(q => $address, output => 'csv', key => $key);

    my $response = LWP::UserAgent->new->get($uri);

    return $response->content;
}

#-------------------------------------------------------------------
sub processAddresses {
    my $session = shift;
    my $config  = shift;
    my $data    = shift;
    my $map     = shift;
    my $key     = shift;
    
    my $sidebar;
    # Set up geocode cache
    my $geoCache = WebGUI::Cache->new($session, 'geoCodeCache');
    my $geoCodes = $geoCache->get || {};

    my $templateId = $config->{infoboxtemplate} ;#|| 'FyaUpoBEZoYECb-MKWkZGg';
    my $template;
    if ($templateId) {
        $template = WebGUI::Asset->newByDynamicClass($session, $templateId);
    }

    my @addressComposition = split(/;/, $config->{addresscomposition});
    @addressComposition = split(/;/, $config->{defaultAddressComposition}) unless (@addressComposition);

    my @nameComposition = split(/;/, $config->{namecomposition});
    @nameComposition = qw(firstName middleName lastName) unless (@nameComposition);

    # Set up markers
    my ($markers, $markerCount, $totalLatitude, $totalLongtitude);
    foreach my $entry (@$data) {
        my $address = join(' ', map {$entry->{$_}} @addressComposition) || $entry->{address};

        # Replace weird whitespace blocks in address with nice clean spaces.
        $address =~ s/\s+/ /g;

        my $geoCode = undef;
        if (exists $geoCodes->{$address}) {
            $geoCode = $geoCodes->{$address};
        }
        else {
            my ($code, $accuracy, $latitude, $longtitude) = split(/,/, geocodeAddress($session, $address, $key));

            # Only process succeeded geocode lookups
            if ($code == 200) {
                $geoCode = "$latitude,$longtitude";
                $geoCodes->{$address} = $geoCode;
            }
        }

        # Skip failed geocode lookups
        next unless defined $geoCode;

        my $markerContent;
        if ($template) {
            $markerContent = $template->process($entry);
        }
        else {
            my $templateCode = (exists $config->{group}) ? $groupsTemplate : $xmlTemplate;
            $markerContent = WebGUI::Asset::Template->processRaw($session, $templateCode, $entry);
        }
        $markerContent =~ s/\\/\\\\/g;
        $markerContent =~ s/"/\\"/g;
        $markerContent =~ s/[\n\r]/\\n/g;

        (my $markerId = 'mark_'.$session->id->generate) =~ s/\-/\$/g;
        (my $pointId = 'point_'.$session->id->generate) =~ s/\-/\$/g; 
        $markers .= <<EOM;
            var $pointId = new GLatLng($geoCode);
            var $markerId = new GMarker($pointId);
            $map.addOverlay($markerId);
            bounds.extend($pointId);
EOM
    
        unless (exists $config->{address}) {
            $markers .= <<POPUP;
            GEvent.addListener($markerId, "click", function() {
                $markerId.openInfoWindowHtml("$markerContent");
            });
POPUP
        }

        if ($config->{showsidebar}) {
            $sidebar .= '<div onclick="GEvent.trigger('.$markerId.',\'click\')">'
                .join(' ', map{$entry->{$_}} @nameComposition)
                .'</div>';
        }
    }

    # Cache geo codes. Keep for a day.
    $geoCache->set($geoCodes, 24*60*60);

    return ($markers, $sidebar);
}

#-------------------------------------------------------------------
sub process {
	my $session = shift;

    my $config;
    # Parse configuration options
    foreach (@_) {
        $_ =~ /^([^=]+)=(.+)$/;

        $config->{lc($1)} = $2;
    }

    my $sidebar;

    # Fetch data
    my $data;
    if (exists $config->{group}) {
        $data = getDataFromGroup($session, $config->{group});
        $config->{defaultAddressComposition} = 'homeAddress;homeZip;homeCity;homeState;homeCountry';
    }
    elsif (exists $config->{xml}) {
        $data = getDataFromXML($session, $config->{xml}, $config->{xmlcontainer});
        $config->{defaultAddressComposition} = 'address;zip;city;state;country';
    }
    elsif (exists $config->{address}) {
        $data = [ { address => $config->{address} } ];
    }
    else {
        return 'No datasource given.';
    }

    # Get key
    my $key = $config->{key} || $session->config->get('googleMapsApiKey');
    return 'No google maps api key given.' unless ($key);   

    my $mapId = $session->id->generate;
    my $divId = "map_$mapId";
    (my $map  = "map_$mapId") =~ s/\-/\$/g;

    my ($markers, $sidebar) = processAddresses($session, $config, $data, $map, $key);

    my $scriptLoader = <<EOHEAD;
    <style type="text/css">
        v\:* {
            behavior:url(#default#VML);
        }
    </style>
 
    <script src="http://maps.google.com/maps?file=api&v=2.x&key=$key" type="text/javascript"></script>
EOHEAD
    
    my $mapWidth = $config->{width} || 500;
    my $mapHeight = $config->{height} || 300;
    
    my $mapDiv = "<div><div id=\"$divId\" style=\"border: 1px solid black; width: "
        .$mapWidth."px; height: ".$mapHeight."px;\"></div></div>";

    my $javascript = <<EOMAP;
    <script type="text/javascript">
        //<![CDATA[

        if (GBrowserIsCompatible()) {
            var $map = new GMap2(document.getElementById("$divId"));

            $map.addControl(new GSmallMapControl());
            $map.addControl(new GMapTypeControl());

            $map.setCenter(new GLatLng(0, 0), 0);
            var bounds = new GLatLngBounds();

            $markers

            $map.setZoom($map.getBoundsZoomLevel(bounds));
            $map.setCenter(bounds.getCenter());
        }

        //]]>
    </script>
EOMAP

    return "$scriptLoader<table><tr><td>$mapDiv</td><td><div class=\"sidebar\" style=\"height:"
        .$mapHeight."px; overflow: auto\">$sidebar</div></td></tr></table>$javascript";
}

1;

