#!/usr/bin/perl
# $Id: Logger.pm 192 2006-05-11 17:22:33Z trevorj $
# ____________
# Lucy; irc bot
# ~trevorj <[trevorjoynson@gmail.com]>
#
#	Copyright 2006 Trevor Joynson
#
#	This file is part of Lucy.
#
#	Lucy is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	Lucy is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with Lucy; if not, write to the Free Software
#	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
package Lucy::Diamonds::Logger;
use base qw(Lucy::Diamond);
use POE;
use Cwd;
use Fcntl qw(:DEFAULT :flock :seek);
use warnings;
use strict;

#no strict "refs";

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless { priority => -1 }, $class;
}

###
### I used to use a queue for logging, but I found it just wasn't worth the code it required.
### The OS should be able to take care of disk queueing.
sub log {
	my ( $self, $log, $payload ) = @_;
	return unless defined $log;
	
	$log =~ s/\.log$//;

	eval {
		unless ( defined $self->{logs}{$log} )
		{
			$self->{logs}{$log} = $self->_openlog( cwd() . "/log/$log.log" );
			$self->log( $log, '-!- Opened log file' )
			  if defined $self->{logs}{$log};
		}
		return unless defined $self->{logs}{$log};
		$payload = time . ' ' . $payload . "\n";
		sysseek $self->{logs}{$log}, 0, SEEK_END;
		syswrite $self->{logs}{$log}, $payload, length($payload);
	};
}

sub _openlog {
	my ( $self, $filename ) = @_;
	my $log;
	Lucy::debug( "Logger", "Opening log $filename\n", 8 );

# sync; async;
#sysopen $log, $filename, O_WRONLY | O_CREAT | O_SYNC | O_APPEND or return undef;
	sysopen $log, $filename, O_WRONLY | O_CREAT | O_APPEND or return undef;
	flock $log, LOCK_EX;
	return $log;
}

sub _closelog {
	my ( $self, $log ) = @_;
	return close $log;
}

#TODO does this work??
sub DESTROY {
	my $self = shift;
	Lucy::debug( "Logger", "Cleaning up...", 8 );

	foreach ( keys %{ $self->{logs} } ) {
		$self->_closelog( $self->{logs}{$_} );
	}
}

1;
