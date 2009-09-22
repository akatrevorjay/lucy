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
package Lucy::Diamonds::Responses;
use base qw(Lucy::Diamond);
use POE;
use warnings;
use strict;

sub tablename     { return 'lucy_responses'; }
sub tablename_map { return 'lucy_responsemap'; }

### The acronyms of defeat shall pwn thee
sub irc_public {
	return unless ( int( rand(6) ) == 1 );

	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	my $responsecmd = ( split( /\s+/, $what, 2 ) )[0];

	my $tr = { command => 'public', nick => $nick, where => $where };
	$tr->{args} = $what if defined $what;
	$tr->{args_or_nick} = ( length($what) > 0 ) ? $what : $nick;

	#$tr->{args_or_nick} = $nick;

	if ( my $res = $self->getresponse( $responsecmd, $tr ) ) {
		if ( $res->{type} eq 'action' ) {
			$lucy->yield( ctcp => $where => ACTION => $res->{response} );
		} elsif ( $res->{type} eq 'reply' ) {
			$lucy->yield(
				privmsg => $where => $nick . ': ' . $res->{response} );
		} else {
			$lucy->yield( privmsg => $where => $res->{response} );
		}

		return 1;
	}

	undef $tr;
}

### I'm Spider Man, Bitch.
sub irc_bot_command {
	my ( $self, $kernel, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, KERNEL, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	my $tr = { command => $cmd, nick => $nick, where => $where };
	$tr->{args} = $args if defined $args;
	$tr->{args_or_nick} = ( length($args) > 0 ) ? $args : $nick;

	if ( my $res = $self->getresponse( $cmd, $tr, $args ) ) {
		if ( $res->{type} eq 'action' ) {
			$lucy->yield( ctcp => $where => ACTION => $res->{response} );
		} elsif ( $res->{type} eq 'reply' ) {
			$lucy->yield(
				privmsg => $where => $nick . ': ' . $res->{response} );
		} else {
			$lucy->yield( privmsg => $where => $res->{response} );
		}

		return 1;
	}
}

sub getresponse {
	my $self = shift;
	my $cmd  = shift;
	my $tr   = shift || {};
	my $args = shift;

	if ( my $map = $self->getresponsemap($cmd) ) {
		if ( my $res = $self->getresponsefromkey( $map->{responsekey} ) ) {
			if (
				my $response = $self->tre_filter(
					$res->{response}, $tr, $map->{args_regex}, $args
				)
			  )
			{
				return undef unless ( length($response) > 0 );
				$res->{response} = $response;
				return { type => $res->{type}, response => $res->{response} };
			}
		}
	}
}

sub getresponsemap {
	my $self    = shift;
	my $command = shift;

	if (
		my $q = $Lucy::dbh->query(
			'SELECT responsekey, args_regex FROM '
			  . $self->tablename_map
			  . ' WHERE command = ? LIMIT 1',
			$command
		)
	  )
	{
		$q = $q->hash;
		return $q if defined $q->{responsekey};
	}
	return undef;
}

sub getresponsefromkey {
	my $self = shift;
	my $key  = shift;

	#TODO should this use the other random row query method for large tables
	if (
		my $q = $Lucy::dbh->query(
			'SELECT response, type FROM '
			  . $self->tablename
			  . ' WHERE `key` = ? ORDER BY RAND() LIMIT 1',
			$key
		)
	  )
	{
		$q = $q->hash;
		return $q if defined $q->{response};
	}
	undef;
}

sub tre_filter {
	my $self  = shift;
	my $str   = shift;
	my $tr    = shift;
	my $regex = shift || undef;
	my $args  = shift || undef;

	if ( defined $regex && length($regex) > 0 && defined $args ) {
		if ( $args =~ /$regex/ ) {
			my $count = 1;
			while ( my $m = eval( 'return $' . $count . ' or undef;' ) ) {
				$tr->{ 'arg' . ( $count - 1 ) } = $m;
				$count++;
			}
		} else {
			Lucy::debug( "Responses", "tre_filter: args didn't match the regex",
				7 );
			return 0;
		}
	}

	# replace the %var%'s with $var's
	foreach ( keys %{$tr} ) {
		$str =~ s/%$_%/$tr->{$_}/;
	}

	return $str;
}

### Mmmm. We have been loaded.
sub new {
	return bless {}, shift;
}

1;
