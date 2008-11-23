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
package Lucy::Diamonds::WWWSearch;
use base qw(Lucy::Diamond);
use POE;
use warnings;
use strict;
use WWW::Search;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	my $self = bless {}, $class;

	$self->_get_config;
	return $self;
}

## Keeps an internal hash to keep track of which commands belong to us,
## instead of going through each one every time.
sub _get_config {
	my $self = shift;
	my $mc   = $Lucy::config->{Diamond_Config}{WWWSearch};

	foreach my $m_nugget ( keys %{$mc} ) {
		my $m =
		  ( exists $mc->{$m_nugget}{Module} )
		  ? $mc->{$m_nugget}{Module}
		  : $m_nugget;
		foreach ( @{ $mc->{$m_nugget}{Commands} } ) {
			$self->{cmd_map}{$_} = $m_nugget;
			$self->{mod_map}{$m_nugget} = $m;
		}
	}
}

sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	unless ( exists $self->{cmd_map}{$cmd} && defined $args ) {
		return undef;
	}

	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	my $max_results = 2;
	if ( $args =~ s/\s+max=([1-5])$// ) {
		$max_results = $1;
	}
	$where = $where->[0];
	Lucy::debug( 'WWWSearch', 'query for [' . "$cmd:$args" . ']', 6 );

	my $m_nugget = $self->{cmd_map}{$cmd};
	my $m        = $self->{mod_map}{$m_nugget};
	my $m_config = $Lucy::config->{Diamond_Config}{WWWSearch}{$m_nugget};

	my $search = WWW::Search->new( $m, %{ $m_config->{CreateArgs} } );
	$search->native_query($args);

	my $i = 1;
	while ( my $result = $search->next_result() ) {
		if ( $i > $max_results ) {
			last;
		} elsif ( $i == 1 ) {
			$lucy->privmsg( $where,
				Lucy::font( 'red', $nick ) . ': Result for ' . $args );
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
			Lucy::font( 'red', $nick ) . ': No result found for ' . $args );
	}

	return 1;
}

1;
