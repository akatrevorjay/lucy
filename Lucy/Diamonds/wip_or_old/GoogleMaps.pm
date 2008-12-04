#!/usr/bin/perl
# SVN: $Id: GoogleMaps.pm 55 2008-11-24 05:43:05Z trevorj $
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
package Lucy::Diamonds::GoogleMaps;
use base qw(Lucy::Diamond);
use warnings;
use strict;
use Geo::Google;

sub commands {
	return { directions => [qw(directions)], };
}

sub directions {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'GoogleMaps', 'query for [' . $v->{query} . ']', 6 );

	my $g = Geo::Google->new();

	my $step = 0;
	$step = $v->{query} =~ s/step=(\d+)$//;

	my ( $from, $to ) =
	  $v->{query} =~ /(?:from\s+)?([\d\w\s,\.-]+)\s+to\s+([\d\w\s,\.-]+)/;

	my ($gfrom) = $g->location( address => $from );
	my ($gto)   = $g->location( address => $to );
	my ($gpath) = $g->path( $gfrom, $gto );
	my @gsegments = $g->segments($gpath);

	if ( $step > 0 ) {
		push( @msg, "$step. " . $gsegments[$step]->text() );
	} else {
		my $i = 1;
		foreach (@gsegments) {
			push( @msg, "$i. " . $_->text() );
			$i++;
		}
	}

	#	if ( $result->error ) {
	#		push( @msg,
	#			$result->message
	#			  . Lucy::font( 'red bold', ' [error=' . $result->code . ']' ) );
	#	} else {
	#		push( @msg,
	#			$result->translation
	#			  . Lucy::font( 'yellow bold', ' [lang=' . $result->language . ']' )
	#		);
	#	}

	undef $g;
	return \@msg;
}

1;
