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
package Lucy::Diamonds::FileServe;
use POE;
use warnings;
use strict;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
 save for fileserv plugin
	unless ( defined $Lucy::config->{FileServeRoot} ) {
		warn(
"!!! $class: There is no \$config->{FileServeRoot} in your configfile, refusing to load."
		);
		return undef;
	}
	return bless {}, $class;
}

sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	unless ( $cmd eq 'send'
		&& defined $Lucy::config->{FileServeRoot}
		&& $args =~ /[\w\s]+/ )
	{

# it is important to return 0 when you want the event to continue to other plugins
		return 0;
	}
	my $nick = ( split /[@!]/, $who, 2 )[0];
	$where = $where->[0];
	Lucy::debug( 'FileServ', "query for [$args]", 6 );

	if ( -e $Lucy::config->{FileServeRoot} . $args ) {
		$lucy->privmsg( $where, Lucy::font( 'yellow', $nick ) . ': ok.' );
	} else {
		$lucy->privmsg( $where,
			Lucy::font( 'red', '!! ' ) . 'I can\'t do that Dave.' );
	}
}

sub irc_dcc_request {
	my ( $kernel, $nick, $type, $port, $magic, $filename, $size ) =
	  @_[ KERNEL, ARG0 .. ARG5 ];

	print "DCC $type request from $nick on port $port\n";
	$nick = ( $nick =~ /^([^!]+)/ );
	$nick =~ s/\W//;
	$kernel->post( 'dcc_accept', $magic, "$1.$filename" );
}

sub irc_dcc_done {
	my ( $magic, $nick, $type, $port, $file, $size, $done ) =
	  @_[ ARG0 .. ARG6 ];
	print "DCC $type to $nick ($file) done: $done bytes transferred.\n",;
}

sub irc_dcc_error {
	my ( $err, $nick, $type, $file ) = @_[ ARG0 .. ARG2, ARG4 ];
	print "DCC $type to $nick ($file) failed: $err.\n",;
}

1;
