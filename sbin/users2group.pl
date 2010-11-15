#!/usr/bin/env perl

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2009 Plain Black Corporation.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#-------------------------------------------------------------------

$|++; # disable output buffering
our ($webguiRoot, $configFile, $help, $man, $groupId, $profileField, $value);

BEGIN {
    $webguiRoot = "..";
    unshift (@INC, $webguiRoot."/lib");
}

use strict;
use Pod::Usage;
use Getopt::Long;
use WebGUI::Session;

# Get parameters here, including $help
GetOptions(
    'configFile=s'  => \$configFile,
    'help'          => \$help,
    'man'           => \$man,
    'groupId=s'		=> \$groupId,
    'profileField=s'=> \$profileField,
    'value=s'		=> \$value,
);

pod2usage( verbose => 1 ) if $help;
pod2usage( verbose => 2 ) if $man;
pod2usage( msg => "Must specify a config file!" ) unless $configFile;  

my $session = start( $webguiRoot, $configFile );
# Do your work here
addUsersToGroup( $session );
finish($session);

#----------------------------------------------------------------------------
# Your sub here
sub addUsersToGroup {
		my $session = shift;
		# get userIds
		my $sql = qq| select userId from userProfileData where $profileField = ?|;
		print "sql: " . $sql . "\n";
		print "value: " . $value . "\n";
		my @users = $session->db->buildArray( $sql,[$value] );
		print "users: " . @users . "\n";
		# instantiate user and add to group
		my $counter = 0;
		foreach my $id( @users ) {
			print "id: $id\n";
			$counter++;
			my $u = WebGUI::User->new( $session, $id );
			my $userName = $u->get( "username" );
			$u->addToGroups( [$groupId] );
			print "Instantiated $counter user $userName and added to group\n";
		}
}


#----------------------------------------------------------------------------
sub start {
    my $webguiRoot  = shift;
    my $configFile  = shift;
    my $session = WebGUI::Session->open($webguiRoot,$configFile);
    $session->user({userId=>3});
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    #
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->set({name => 'Add users met profileField $profileField is $value to group $groupId'});
    #
    ##
    
    return $session;
}

#----------------------------------------------------------------------------
sub finish {
    my $session = shift;
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    #
    my $versionTag = WebGUI::VersionTag->getWorking($session);
    $versionTag->commit;
    ##
    
    $session->var->end;
    $session->close;
}

__END__


=head1 NAME

utility - A template for WebGUI utility scripts

=head1 SYNOPSIS

 utility --configFile config.conf ...

 utility --help

=head1 DESCRIPTION

This WebGUI utility script helps you...

=head1 ARGUMENTS

=head1 OPTIONS

=over

=item B<--configFile config.conf>

The WebGUI config file to use. Only the file name needs to be specified,
since it will be looked up inside WebGUI's configuration directory.
This parameter is required.

=item B<--help>

Shows a short summary and usage

=item B<--man>

Shows this document

=back

=head1 AUTHOR

Copyright 2001-2009 Plain Black Corporation.

=cut

#vim:ft=perl
