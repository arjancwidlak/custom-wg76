package WebGUI::Macro::ScoredSurvey; 

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2008 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;

=head1 NAME

Package WebGUI::Macro::ScoredSurvey

=head1 DESCRIPTION

Macro to display a sum of all scores from all scored surveys entered in the macro.

=head2 process( $session, [scoredsAssetId1,scoredsAssetId1,....] )

The main macro class.

=over 4

=item *

A session variable

=item *

Any other options that were sent to the macro by the user.  It is up to you to set defaults and
to validate user input.

=back

=cut


#-------------------------------------------------------------------
sub process {
	my $session = shift;
    my $score = 0;
    while (my $assetId = shift) {
        $score += $session->db->quickScalar("SELECT SUM(ScoredSurvey_answer.score) 
                            FROM ScoredSurvey_response
                            LEFT JOIN ScoredSurvey_answer 
                            USING(ScoredSurvey_answerId,ScoredSurvey_questionId ) 
                            WHERE ScoredSurvey_response.assetId=?",[$assetId]);
    }
	return $score;
}

1;


