package WebGUI::Macro::addFormVars;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Macro;

=head1 NAME

Package WebGUI::Macro::addFormVars

=head1 DESCRIPTION

Macro for setting form variables even if the current url has already a 
query string.

=head2 process ( [url],[key,value] )

=head3 url

The url of the current page or the page where you would like to go. 
If no url is given, the url of the current page will be used.

=head3 key

key/value pairs kan be given to the macro. The amount of key/value 
pairs is only limited by the maximum length of a URL in general.

=cut

#-------------------------------------------------------------------
sub paramsFromUrl {
	my $url2split = shift;
	my ($url,$params2parse) = split(/\?/, $url2split);
	my @paramPairs = split(/;/, $params2parse);
	my %params;
	foreach my $paramPair(@paramPairs) {
		my ($paramKey,$paramValue) = split(/=/,$paramPair);
		$params{$paramKey} = $paramValue;
	}
	return ($url, %params);
}

sub process {
	my $session = shift;
	my $url = shift;
	my @macroParams = @_;

	my %macroParams;
	my $cleanUrl;
        my %urlParams;
	
	# convert the array to a hash
        my $params = @macroParams;
        for (my $i=0; $i < $params; $i += 2) {
                $macroParams{$macroParams[$i]} = $macroParams[($i+1)];
        }
	
	if ($url) {
		($cleanUrl, %urlParams) = paramsFromUrl($url);
	}else{
		$cleanUrl = $session->url->getRequestedUrl; 
		#$session->url->page();
		foreach my $var ($session->form->param) {
			$urlParams{$var} = $session->form->process($var);
		}
	}

	
	# When a value in the url is set in the macro, it should not be set twice.
	foreach my $urlKey (keys %urlParams) {
		foreach my $macroKey (keys %macroParams) {
			delete $urlParams{$urlKey} if $macroKey eq $urlKey;
		}
	}
	
	$cleanUrl .= "?";
	
	# First add the url values
	foreach my $key (keys %urlParams) {
		$cleanUrl .= $key . "=" . $urlParams{$key} . "&";
	}	

	# Then add the macro values:
	my @keys = keys ( %macroParams );
	my $keys = @keys;
	for (my $i=0; $i<$keys; $i++) {
		$cleanUrl .= $keys[$i] . "=" .$macroParams{$keys[$i]};
		unless ($i == $keys-1) { $cleanUrl .= "&"; }
	}

	return $cleanUrl;
}

1;


