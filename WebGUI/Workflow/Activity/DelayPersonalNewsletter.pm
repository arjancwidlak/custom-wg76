package WebGUI::Workflow::Activity::DelayPersonalNewsletter;


=head1 LEGAL

 -------------------------------------------------------------------
  WebGUI is Copyright 2001-2009 Plain Black Corporation.
 -------------------------------------------------------------------
  Please read the legal notices (docs/legal.txt) and the license
  (docs/license.txt) that came with this distribution before using
  this software.
 -------------------------------------------------------------------
  http://www.plainblack.com                     info@plainblack.com
 -------------------------------------------------------------------

=cut

use strict;
use base 'WebGUI::Workflow::Activity';
#use WebGUI::VersionTag;

=head1 NAME

Package WebGUI::Workflow::Activity::WaitUntil

=head1 DESCRIPTION

This workflow activity waits until the version tag start or end date as specified before proceeding.

=head1 SYNOPSIS

See WebGUI::Workflow::Activity for details on how to use any activity.

=head1 METHODS

These methods are available from this class:

=cut

#-------------------------------------------------------------------

=head2 definition ( session, definition )

See WebGUI::Workflow::Activity::defintion() for details.

=cut

sub definition {
    my $class = shift;
    my $session = shift;
	my $definition = shift;
	my $i18n = WebGUI::International->new($session, "VersionTag");
	push(@{$definition}, {
		name=>'Delay Personal Newsletter',
		properties=> { 
        }
    });
	return $class->SUPER::definition($session,$definition);
}


#-------------------------------------------------------------------

=head2 execute (  )

See WebGUI::Workflow::Activity::execute() for details.

=cut

sub execute {
	my $self       = shift;
	my $object      = shift;
    my $instance    = shift;
    my $session    = $self->session;
	my $urlOfSingleAsset = "";

    #By default, we'll make it so that things happen now.
    #my $time = $session->datetime->time();
    my @parameters = @{$instance->get('parameters')};
    my $time = $parameters[0];
    $session->errorHandler->info('startTijd: '.$time);
    
    #Turn start or end time into an epoch value
    my $dt = WebGUI::DateTime->new($session,$time);
    
    #Get the current UTC time
    my $now = WebGUI::DateTime->new($session,time());
    
    #Workflow is complete if the time has passed.
    if($now->epoch >= $dt->epoch) {
        return $self->COMPLETE;
    }
        
    return $self->WAITING($dt->epoch - $now->epoch);
}



1;


