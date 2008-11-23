#!/usr/bin/perl
# SVN: $Id: Google.pm 140 2006-04-04 22:09:16Z trevorj $
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

package Lucy::Diamonds::Google_ng;
use POE;
use WWW::Search;
use POE::Component::Generic;
use warnings;
use strict;

#use Net::Google::Spelling;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	my $self = bless {}, $class;
	return $self if $self->init;
}

sub init {
	my $self = shift;
	$Lucy::lucy->add_event(qw(google_query google_result google_url));
	$self->{google} = POE::Component::Generic->spawn(

		# required; main object is of this class
		package => 'WWW::Search',

		# optional; Options passed to Net::Telnet->new()
		object_options => [ 'Google', key => $Lucy::config->{GoogleApi_Key} ],

		# optional; You can use $poco->session_id() instead
		alias => 'google',

		# optional; 1 to turn on debugging
		debug => 1,

		# optional; 1 to see the child's STDERR
		verbose => 1,

		# optional; Options passed to the internal session
		options => { trace => 1 },

		# optional; describe package signatures
		packages => {
			'WWW::Search' => {

				methods => [qw(maximum_to_retrieve native_query next_result)],

				# Methods that require coderefs, and keep them after they
				# return.

				# The first arg is converted to a coderef
				postbacks => [qw(next_result)],
				factories => [qw(native_query next_result)]

				  #callbacks => { 'query' => 0 }
			},

			'WWW::SearchResult' => {
#
#				# only these methods are exposed
				methods => [qw(url title description)],
#
#				# Methods that require coderefs, but don't keep them
#				# after they return
#				#callbacks => [qw( two )]
			}
		}
	);
}

sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	unless ( ( $cmd eq 'google' )
		&& ( defined $Lucy::config->{GoogleApi_Key} ) )
	{

# it is important to return 0 when you want the event to continue to other plugins
		return 0;
	}
	$where = $where->[0];
	Lucy::debug( 'Google', "query for [$args]", 6 );

	if ( length($args) > 3 ) {

# tell the child process to run the search, and send the results to the got_search function
		$self->{google}->maximum_to_retrieve( {},
			( $args =~ s/\s+max=([1-5])$// ) ? $1 : 2 );
		$self->{google}->native_query(
			{
				event => 'google_query',
				data  => $where
			},
			WWW::Search::escape_query($args)
		);

	} else {
		$lucy->privmsg( $where,
			Lucy::font( 'red', '!! ' )
			  . 'Searches have a 4 character minimum' );
	}
}

# result state
sub google_url {
	my ( $kernel, $ref, $result ) = @_[ KERNEL, ARG0, ARG1 ];

	print "google_url: " . $result . "\n";

	if ( $ref->{error} ) {
		print "google_result: error " . join( ' ', @{ $ref->{error} } ) . "\n";
		return undef;
	}

	#my $i = 1;
	#$Lucy::lucy->privmsg( $ref->{data},
	#	Lucy::font( 'yellow bold', "$i. " ) . $result->url() );
	#		$i++;
	#undef $i;
}

# result state
sub google_result {
	my ( $kernel, $ref, $result ) = @_[ KERNEL, ARG0, ARG1 ];

	print "google_result: " . $result->url( {event => 'google_url', data => $ref->{data}} ) . "\n";

	if ( $ref->{error} ) {
		print "google_result: error " . join( ' ', @{ $ref->{error} } ) . "\n";
		return undef;
	}

	#my $i = 1;
	#$Lucy::lucy->privmsg( $ref->{data},
	#	Lucy::font( 'yellow bold', "$i. " ) . $result->url() );
	#		$i++;
	#undef $i;
}

# result state
sub google_query {
	my ( $kernel, $self, $sender, $ref ) = @_[ KERNEL, OBJECT, SENDER, ARG0 ];

	$self->{google}->next_result(
		{
			event => 'google_result',

			#			session => $Lucy::sessid,
			data => $ref->{data}
		}
	);
	print "google_query: \n";
	
	if ( $ref->{error} ) {
		print "google_query: error " . join( ' ', @{ $ref->{error} } ) . "\n";
		return undef;
	}
}

1;
