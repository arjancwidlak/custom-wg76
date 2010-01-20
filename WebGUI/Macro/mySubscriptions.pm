package WebGUI::Macro::mySubscriptions;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2005 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
use WebGUI::Utility;

=head1 NAME

Package WebGUI::Macro::mySubscriptions;

=head1 DESCRIPTION

Templatable macro for displaying a Post. This macro can be used in SQL 
Report Templates that search through posts. 

=head2 process ( assetId, templateId )

=head3 assetId

The assetId of the Newsletter asset.

=head3 templateId

The templateId of the template to use with this macro.

=cut

#-------------------------------------------------------------------

sub process {
        my $session = shift;

        my $assetId = shift;
	my $templateId = shift;
	
	my $newsletter = WebGUI::Asset->newByDynamicClass($session, $assetId);
	my %var = ();
	my $meta = $newsletter->getMetaDataFields;
	my @categories = ();
        my @userPrefs = $newsletter->getUserSubscriptions;
	foreach my $id (keys %{$meta}) {
        	my @options = ();
        	if (isIn($id, split("\n", $newsletter->get("newsletterCategories")))) {
        	    foreach my $option (split("\n", $meta->{$id}{possibleValues})) {
        	        $option =~ s/\s+$//;    # remove trailing spaces
        	        next if $option eq "";  # skip blank values
        	        my $preferenceName = $id."~".$option;
        	        my $checked;
        	        $checked = "checked=\"checked\"" if isIn($preferenceName, @userPrefs);
        	        push(@options, {
        	            optionName  => $option,
        	            preferenceName => $preferenceName,
        	            checked => $checked,
        	            optionForm  => WebGUI::Form::checkbox($session, {
        	                    name    => "subscriptions",
        	                    value   => $preferenceName,
        	                    checked => isIn($preferenceName, @userPrefs),
        	                    })
        	            });
        	    }
        	    push (@categories, {
        	        categoryName    => $meta->{$id}{fieldName},
        	        optionsLoop     => \@options
        	        });
        	}
    	}
    	$var{categoriesLoop} = \@categories;
	if (scalar(@categories)) {
        	$var{formHeader} = WebGUI::Form::formHeader($session, {action=>$newsletter->getUrl, method=>"post"})
		.WebGUI::Form::hidden($session, {name=>"func", value=>"mySubscriptionsSave"});
	        $var{formFooter} = WebGUI::Form::formFooter($session);
        	$var{formSubmit} = WebGUI::Form::submit($session);
    	}
    	return $newsletter->processTemplate(\%var, $templateId);
}
1;
