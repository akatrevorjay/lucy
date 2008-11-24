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
package Lucy::Diamonds::GoogleTranslator;
use base qw(Lucy::Diamond);
use warnings;
use strict;
use WebService::Google::Language;

sub commands {
	return { search => [qw(translate translator trans)], };
}

sub search {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'GoogleTranslator', 'query for [' . $v->{query} . ']', 6 );

	my $glang  = WebService::Google::Language->new( %{ $v->{config} } );
	my $result = $glang->translate( $v->{query} );

	if ( $result->error ) {
		push( @msg,
			$result->message
			  . Lucy::font( 'red bold', ' [error=' . $result->code . ']' ) );
	} else {
		push( @msg,
			  $result->translation
			  . Lucy::font( 'yellow bold', ' [lang=' . $result->language . ']' )
		);
	}

	#  $result = $service->detect('Bonjour tout le monde');
	#  printf "Detected language: %s\n", $result->language;
	#  printf "Is reliable:       %s\n", $result->is_reliable ? 'yes' : 'no';
	#  printf "Confidence:        %s\n", $result->confidence;

	undef $glang;
	return \@msg;
}

1;
