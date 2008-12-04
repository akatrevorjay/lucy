#!/usr/bin/perl
# SVN: $Id: Google_ng.pm 55 2008-11-24 05:43:05Z trevorj $
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

sub commands {
	return { search => [qw(urban_ng urbanng urban2)], };
}

sub init {
	my $self = shift;

	#$Lucy::lucy->add_event(qw(google_query google_result google_url));
	$self->{urban} = POE::Component::Generic->spawn(

		# required; main object is of this class
		package => 'WWW::Search',

		# optional; Options passed to Net::Telnet->new()
		object_options => [
			'UrbanDictionary',
			key => $Lucy::config->{Diamond_Config}{Google}{key},
		],

		# optional; You can use $poco->session_id() instead
		alias => 'urban',

		# optional; 1 to turn on debugging
		debug => 1,

		# optional; 1 to see the child's STDERR
		verbose => 1,

		# optional; Options passed to the internal session
		options => { trace => 1 },

		# optional; describe package signatures
		packages => {
			'WWW::Search' => {

				# Methods that require coderefs, and keep them after they
				# return.

				# The first arg is converted to a coderef
				#postbacks => [qw(next_result)],

				factories => [qw(next_result)]

				  #callbacks => { 'query' => 0 }
			},
		}
	);
}

sub search {
	my ( $self, $v ) = @_;

	Lucy::debug( 'UrbanDictionary', 'query for [' . $v->{query} . ']', 6 );

	$self->{urban}->native_query( { event => 'got_query' }, $v->{query} );
}

sub urbanng_got_query {
	my ( $self, $lucy, $search ) = @_[ OBJECT, SENDER, ARG0 ];
	
	my $max_results = 3;

	my $i = 1;
	while ( my $result = $search->next_result() ) {
		if ( $i > $max_results ) {
			last;
		}

		my $description = $result->{definition};
		$description =~ s/\n/ /g;
		push( @msg,
			    $description . ' ['
			  . Lucy::font( 'red', $result->{author} )
			  . ']' );
		if ( my $example = $result->{example} ) {
			$example =~ s/\n/ /g;
			push( @msg, Lucy::font( 'yellow bold', "ex: " ) . $example );
		}

		$i++;
	}
	if ( $i == 1 ) {
		return undef;
	}
}

1;
