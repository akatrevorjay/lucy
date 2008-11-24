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
package Lucy::Diamonds::Google;
use base qw(Lucy::Diamond);
use warnings;
use strict;
use Google::Search;

sub commands {
	return { search => [qw(google g goog search)], };
}

sub search {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'Google', 'query for [' . $v->{query} . ']', 6 );

	my $max_results = 2;
	if ( $v->{query} =~ s/\s+max=([1-5])$// ) {
		$max_results = $1;
	}

	$v->{config}{q} = $v->{query};
	my $search = Google::Search->Web( %{ $v->{config} } );
	my $result = $search->first;

	my $i = 1;
	while ($result) {
		last if ( $i > $max_results );

		push( @msg,
			Lucy::font( 'bold', $result->number . '.' ) . " "
			  . $result->uri );
		$i++;
		$result = $result->next;
	}
	undef $search;
	return undef if ( $i == 1 );

	return \@msg;
}

1;
