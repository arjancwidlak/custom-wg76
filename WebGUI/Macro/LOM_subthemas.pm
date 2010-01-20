package WebGUI::Macro::LOM_subthemas;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;

=head1 NAME

Package WebGUI::Macro::LOM_subthemas

=head1 DESCRIPTION

Macro for quoting data to make it safe for use in SQL queries.

=head2 process ( text )

process is really a wrapper around WebGUI::SQL::$session->db->quote();

=head3 text

The text to quote.

=cut

#-------------------------------------------------------------------
sub process {
	my $session = shift;
    my $ignoreFields = shift || '';
    my $templateUrl = shift;

    return 'This macro requires a template url' unless($templateUrl);
   
    my $template = WebGUI::Asset::Template->newByUrl($session,$templateUrl);
    return 'Invalid template url' unless ($template);
    my ($var,@field_loop);
 
    my $output;
    my $sql = "select fieldId, fieldName from metaData_properties ";
    if($ignoreFields){
        $sql .=  " where !(fieldId IN(".$ignoreFields."))";
    }
    $sql .= ' order by fieldName asc';
	my $fields = $session->db->read($sql);
    while (my $field = $fields->hashRef){
        my @possibleValues_loop;
        #$output .= $field->{fieldName}."<br />\n";
        my $possibleValues = $session->db->quickScalar("select possibleValues from metaData_properties where fieldId =?"
            ,[$field->{fieldId}]);
        my @possibleValues = sort(split("\n",$possibleValues));
        foreach my $value (@possibleValues){
	    $value =~ s/[\n\r]//;		
            push(@possibleValues_loop,{value => $value});
            #$output .= "<input type='radio' name='subthema' value='".$field->{fieldId}."|".$value."'>".$value
            #            ."<br />\n";
        }
        #$output .= "<input type='radio' name='subthema' value='".$field->{fieldId}."|'>Alle Subthema's van ".
        #            $field->{fieldName}."<br />\n";
        push(@field_loop,{
            fieldId             => $field->{fieldId}, 
            fieldName           => $field->{fieldName}, 
            possibleValues_loop => \@possibleValues_loop
        });
	}
    #$output .= "<br /><input type='radio' name='subthema' value=''>Alle Subthema's<br />\n";

    $var->{field_loop} = \@field_loop;
    return $template->process($var);
    #return $output;
}


1;

