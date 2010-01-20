package WebGUI::Macro::IfFormParamValue;

use strict;

=head1 LEGAL

Copyright 2007 United Knowledge

See the doc/license-UserList.txt file for licensing information.

http://www.unitedknowledge.nl
developmentinfo@unitedknowledge.nl

=head1 NAME

Package WebGUI::Macro::IfFormParamValue;

=head1 DESCRIPTION

Macro for checking if a form param has a certain value or not.

=head2 process ( paramName, paramValue, ifTrue, ifFalse  )

=head3 paramName

The name of the form param to pull from the session object.

=head3 paramValue

The value of the form param to check for

=head3 ifTrue

What to return if the value form param matches

=head3 ifFalse

What to return if the value of the form param does not match

=cut

#-------------------------------------------------------------------
sub process {
        my $session = shift;
        my ($paramName, $paramValue, $ifTrue, $ifFalse) = @_;
        $paramValue =~ s/^\s+//;
        $paramValue =~ s/\s+$//;
        #print $paramName.", ".$paramValue.", ".$ifTrue.", ".$ifFalse."<br>";
        my $formParamValue = $session->form->process($paramName);
        #print $formParamValue;
        if ($formParamValue eq $paramValue){
                return $ifTrue;
        }else{
                return $ifFalse;
        }
}


1;

