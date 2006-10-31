#!/usr/bin/perl
# SVN: $Id: NetTools_ng.pm 205 2006-05-17 06:29:45Z trevorj $
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

# This is a proof of concept WIP for a non-blocking plugin. I don't like this approach
#  and would much rather make Sky non-blocking when running the events. Threading could do this,
#  and run them in parallel. But threading something with that much shared information is going to be bad.
# So I don't know yet. This is currently very very b0rk and I've gone through tons of hacks to try to make it work.
# Oh well. Another day.

package Lucy::Diamonds::NetTools_ng;
use POE::Component::Generic;

use Net::Ping;
use POE;
use warnings;
use strict;
no strict 'subs';

#use Net::NetTools::Spelling;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

sub irc_bot_command {
	my ( $self, $lucy, $kernel, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, KERNEL, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	if (   ( $cmd eq 'ping' )
		&& ( Lucy::Common::ishostname($args) ) )
	{
		Lucy::debug( 'NetTools', "pinging [$args] for [$nick]", 6 );

		POE::Component::Generic->spawn(

			# required; main object is of this class
			package => 'Net::Ping',

			# optional; Options passed to Net::Telnet->new()
			object_options => [],

			# optional; You can use $poco->session_id() instead
			alias => 'pinger',

			# optional; 1 to turn on debugging
			debug => 0,

			# optional; 1 to see the child's STDERR
			verbose => 1,

			# optional; Options passed to the internal session
			options => { trace => 0 },

			# optional; describe package signatures
			#packages => {
			#	'Net::Ping' => {
			#
			#					# Methods that require coderefs, and keep them after they
			#		# return.
			#
			#					# The first arg is converted to a coderef
			#		postbacks => { ping => 0 }
			#	},
			#	'Net::Ping' => {
			#
			#					# only these methods are exposed
			#		methods => [qw( ping )],
			#
			#					# Methods that require coderefs, but don't keep them
			#		# after they return
			#		callbacks => [qw( two )]
			#	}
			#}
		);
		$kernel->post(
			'pinger' => 'hires', { event => 'got_pong' }
		);
		$kernel->post(
			'pinger' => 'ping', { event => 'got_pong' },
			"frylock"
		);

#($ret, $duration, $ip) = $p->ping($host, 5.5);
#printf("$host [ip: $ip] is alive (packet return time: %.2f ms)\n", 1000 * $duration)
#  if $ret;
#		$pinger->close();
	} else {

# it is important to return 0 when you want the event to continue to other plugins
		return 0;
	}
}

sub got_pong {
	my ( $kernel, $ref, $result, $omg, $omg2 ) =
	  @_[ KERNEL, ARG0, ARG1, ARG2, ARG3 ];

	print "connected: $result|$omg|$omg2\n";

	if ( $ref->{error} ) {
		die join( ' ', @{ $ref->{error} } ) . "\n";
	}

	#	$kernel->post( 'pinger', 'shutdown' );
}
1;
