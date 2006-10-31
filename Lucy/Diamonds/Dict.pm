#!/usr/bin/perl
# SVN: $Id: Dict.pm 85 2006-03-10 21:08:12Z echoline $
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
package Lucy::Diamonds::Dict;
use POE;
use warnings;
use strict;
use WWW::Search;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	unless ( ( ( $cmd eq 'dict' ) || ( $cmd eq 'define' ) )
		&& ( defined $Lucy::config->{UrbanDictApi_key} )
		&& ( defined $args ) )
	{
		return 0;
	}

	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	my $max_results = 2;
	if ( $args =~ s/\s+max=([1-5])$// ) {
		$max_results = $1;
	}
	$where = $where->[0];
	Lucy::debug( 'UrbanDict', 'query for [' . $args . ']', 6 );

	my $search =
	  WWW::Search->new( 'UrbanDictionary',
		key => $Lucy::config->{UrbanDictApi_key} );
	$search->native_query($args);

	my $i = 1;
	while ( my $result = $search->next_result() ) {
		if ( $i > $max_results ) {
			last;
		} elsif ( $i == 1 ) {
			$lucy->privmsg( $where,
				Lucy::font( 'red', $nick ) . ': Definition for ' . $args );
		}
		my $description = $result->{definition};
		$description =~ s/\n/ /g;
		$lucy->privmsg( $where,
			    Lucy::font( 'yellow bold', $i . ': ' )
			  . $description . '['
			  . Lucy::font( 'red', $result->{author} )
			  . ']' );
		if ( my $example = $result->{example} ) {
			$example =~ s/\n/ /g;
			$lucy->privmsg( $where,
				Lucy::font( 'yellow bold', "ex: " ) . $example );
		}
		$i++;
	}
	if ( $i == 1 ) {
		$lucy->privmsg( $where,
			Lucy::font( 'red', $nick ) . ': No definition found for ' . $args );
	}

	return 1;
}

1;
