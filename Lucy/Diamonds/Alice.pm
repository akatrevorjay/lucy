#!/usr/bin/perl
# SVN: $Id$
# _____________
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
package Lucy::Diamonds::Alice;
use base qw(Lucy::Diamond);
use POE;
use IO::Socket;
use warnings;
use strict;

### LOCKNESSSZZZ MONSTA IS MAI BITCH
sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	Lucy::debug( 'Alice', "got command $cmd", 7 );

	my $out;
	if ( my $msg = $self->do_alice( $nick, $cmd . ' ' . $args ) ) {
		$out = Lucy::font( 'bold', $nick ) . ": " . $msg;
	} else {
		$out = Lucy::font( 'red', $nick ) . ": unable to connect to socket";
	}

	$lucy->yield( privmsg => $where => $out );
}

### The acronyms of defeat shall pwn thee
sub irc_public {
	return unless ( int( rand(180) ) == 38 );

	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	my $out;
	if ( my $msg = $self->do_alice( $nick, $what ) ) {
		$out = Lucy::font( 'bold', $nick ) . ": " . $msg;
#	} else {
#		$out = Lucy::font( 'red', $nick ) . ": unable to connect to socket";
	}

	$lucy->yield( privmsg => $where => $out );
}

### Mmmm. We have been loaded.
sub new {
	my $class = shift;

	# use the lowest priority
	return bless { priority => 9 }, $class;
}

### Heart and soul, Yo.
sub do_alice {
	my ( $self, $who, $msg ) = @_;

	my $out;
	if ( my $sock = IO::Socket::UNIX->new('/tmp/alice') ) {
		$sock->write("$who\007$msg");
		$sock->read( $out, 1024 );
		$sock->close;

		undef $sock;
		return ( length($out) > 1 ) ? $out : undef;
	}
}

1;
