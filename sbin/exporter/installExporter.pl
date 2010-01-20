#!/usr/bin/env perl

$|++; # disable output buffering
our ($webguiRoot, $configFile, $quiet);

BEGIN {
    $webguiRoot = "..";
    unshift (@INC, $webguiRoot."/lib");
}

use strict;
use Getopt::Long;
use WebGUI::Session;
use WebGUI::Asset::Wobject::Exporter::DataSource;
use WebGUI::Asset;
use WebGUI::Utility qw{ isIn };

use Data::Dumper;

# Get parameters here, including $help
GetOptions(
    'configFile=s'  => \$configFile,
);


my $session = start( $webguiRoot, $configFile );

installExporterTables( $session );
installPackages( $session );
installTemplateColumn( $session );

finish($session);

#----------------------------------------------------------------------------
sub installTemplateColumn {
    my $session = shift;

    my $hasColumn = $session->db->buildArray( q{show columns from Exporter where Field = 'templateId'} );

    unless ( $hasColumn ) {
        print "\tAdding template column to Exporter table..." unless $quiet;

        $session->db->write( 'alter table Exporter add column templateId char(22) default ?', [
            'qn5FFjaslZH-lo3mhqv59w',
        ] );
        $session->db->write( 'update Exporter set templateId=?', [
            'qn5FFjaslZH-lo3mhqv59w',
        ] );

        print "Done\n" unless $quiet;
    }
}

#----------------------------------------------------------------------------
sub installExporterTables {
    my $session = shift;

    my @tables = $session->db->buildArray( 'show tables' );

    unless ( isIn( 'Exporter_dataSource', @tables ) ) {
        print "\tCreating data source table..." unless $quiet;
        WebGUI::Asset::Wobject::Exporter::DataSource->crud_createTable( $session );
        print "Done\n" unless $quiet;
    }
    else {
        print "\tUpdating data source table..." unless $quiet;
        WebGUI::Asset::Wobject::Exporter::DataSource->crud_updateTable( $session );
        print "Done\n" unless $quiet;
    }

    unless ( isIn( 'Exporter', @tables ) ) {
        print "\tCreating exporter table..." unless $quiet;
        WebGUI::Asset::Wobject::Exporter::DataSource->crud_createTable( $session );
        $session->db->write(<<'END_SQL');
            CREATE TABLE `Exporter` (
                `assetId` char(22) NOT NULL,
                `revisionDate` bigint(20) NOT NULL,
                PRIMARY KEY  (`assetId`,`revisionDate`)
            ) ENGINE=MyISAM DEFAULT CHARSET=utf8
END_SQL
        print "Done\n" unless $quiet;
    }
}

sub installPackages {
    my $session = shift;
    my $tag = WebGUI::VersionTag->getWorking( $session );

    $tag->set( { name => 'Exporter package update' } );

    # This is a bit tricky but should work on linuxes.
    my ($path) = $0 =~ m{^(.+)installExporter\.pl$};
    $path .= '/' if $path && $path !~ m{/$};

    opendir my $DIR, $path;
    my @files = readdir $DIR;
    closedir $DIR;

    for my $file ( @files ) {
        next unless $file =~ m{\.wgpkg$};

        print "\tImporting '$path$file'..." unless $quiet;

        my $storage = WebGUI::Storage->createTemp( $session );
        $storage->addFileFromFilesystem( $path.$file );
        my $asset = WebGUI::Asset->getRoot( $session )->importPackage( $storage );

        print "Done\n" unless $quiet;
    }
    
    $tag->commit;

}

#----------------------------------------------------------------------------
sub start {
    my $webguiRoot  = shift;
    my $configFile  = shift;
    my $session = WebGUI::Session->open($webguiRoot,$configFile);
    $session->user({userId=>3});
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    #
    # my $versionTag = WebGUI::VersionTag->getWorking($session);
    # $versionTag->set({name => 'Name Your Tag'});
    #
    ##
    
    return $session;
}

#----------------------------------------------------------------------------
sub finish {
    my $session = shift;
    
    ## If your script is adding or changing content you need these lines, otherwise leave them commented
    #
    # my $versionTag = WebGUI::VersionTag->getWorking($session);
    # $versionTag->commit;
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
