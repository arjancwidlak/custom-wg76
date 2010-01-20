package WebGUI::Macro::SQLFormReset;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2006 Plain Black Software.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

use strict;
#use WebGUI::Session;
#use WebGUI::SQL;
#use WebGUI::DatabaseLink;
 

#-------------------------------------------------------------------
sub process {
	my $session = shift;
	my ($output, @data, $rownum, $temp, $dbh, $dbLink);
	my ($importUser, $databaseLinkId, $tables) = @_;
	
	if ($databaseLinkId eq "" || $importUser eq "" || $tables eq "") {
		return "This macro needs the id of the user that imported the data set, the id of a databaseLink and a '+'-seperated list of table names.";
	}else{
		if ($session->form->param("mFunc".$session->asset->getId) eq "reset"){
			#print $tables;
			my @tables = split(/\+/,$tables);
			$dbLink = WebGUI::DatabaseLink->new($session,$databaseLinkId);
			$dbh = $dbLink->db;
			foreach my $table (@tables){
				#print "resetting: ".$table;
				my $statement = "delete from $table where __userId != '$importUser'";
				$dbh->write($statement);
				$statement = "delete from $table where __revision != 1";
                                $dbh->write($statement);
				$statement = "update $table set __archived = 0";
				$dbh->write($statement);
				$statement = "update $table set __deleted = 0";
				$dbh->write($statement);
			}
			return "De database is gereset.";
		}else{
			return "<a href='?mFunc".$session->asset->getId."=reset'>Reset</a>";
		}
	}
=cut
	#$format = '^0;' if ($format eq "");
	if ($statement =~ /^\s*select/i || $statement =~ /^\s*show/i || $statement =~ /^\s*describe/i) {
		my $sth = WebGUI::SQL->unconditionalRead($statement,$dbh);
		unless ($sth->errorCode < 1) { 
			return '<p><b>SQL Macro Failed:</b> '.$sth->errorMessage.'<p>';
		} else {
			while (@data = $sth->array) {
                		$temp = $format; 
	                        $temp =~ s/\^(\d+)\;/$data[$1]/g; 
        	                $rownum++;
                	        $temp =~ s/\^rownum\;/$rownum/g;
				$output .= $temp;
	                }
			$sth->finish;
			return $output;
		}
	} else {
		return "Cannot execute this type of query.";
	}
=cut
}


1;

