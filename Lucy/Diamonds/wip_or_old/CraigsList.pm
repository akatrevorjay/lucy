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
package Lucy::Diamonds::CraigsList;
use base qw(Lucy::Diamond);
use warnings;
use strict;
use WWW::Search;

sub commands {
	return { search => [qw(craigs craigslist cl)], };
}

sub search {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'CraigsList', 'query for [' . $v->{query} . ']', 6 );

	my $max_results = 2;
	if ( $v->{query} =~ s/\s+max=([1-5])$// ) {
		$max_results = $1;
	}

	my $search = WWW::Search->new( 'CraigsList', %{ $v->{config} } );
	$search->native_query( WWW::Search::escape_query( $v->{query} ) );

	my $i = 1;
	while ( my $result = $search->next_result() ) {
		if ( $i > $max_results ) {
			last;
		}

		push( @msg,
			    "$i. "
			  . $result->{title} . '['
			  . Lucy::font( 'red', $result->{source} )
			  . ']' );
		push( @msg,
			    "$i. "
			  . $result->{url} . ' ['
			  . Lucy::font( 'red', $result->{change_date} )
			  . ']' );

		$i++;
	}
	if ( $i == 1 ) {
		return undef;
	}

	return \@msg;
}

1;
