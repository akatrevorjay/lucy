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
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	my $responsecmd;
	if ( $what =~ /chuck norris/i ) {
		$responsecmd = 'chuck';
		$what        = "norris";
	} elsif ( $what =~ /smok|marijuana|ganja|bong|joint|blunt/i ) {
		$responsecmd = 'ganja';
	} else {

#TODO choose a random word over over 3 chars and look to see if it's in the db
		return 0;
	}

	return unless ( Lucy::crand(6) == 1 );

	my $args = $what;
	my %tr = ( command => 'public', nick => $nick, where => $where );
	$tr{args} = $args if defined $args;

	#        $tr{args_or_nick} = ( length($args) > 0 ) ? $args : $nick;
	$tr{args_or_nick} = $nick;

##### THIS IS HACKERY. THIS IS FIX ASAP. THIS ARGS SUBST. NEEDS TO BE IN IT'S OWN SUB AND NOT REPEATED.
	if ( my $map = $self->getresponsemap($responsecmd) ) {
		if ( my $res = $self->getresponsefromkey( $map->{responsekey} ) ) {
			if ( defined $map->{args_regex} && defined $args ) {
				if ( $args =~ /$map->{args_regex}/ ) {

					#TODO find a better way of doing this
					$tr{arg0} = $1 || undef;
					$tr{arg1} = $2 || undef;
					$tr{arg2} = $3 || undef;
				} else {
					Lucy::debug( "Responses",
						"irc_public: args didn't match the regex", 7 );
					return 0;
				}
			}

			# replace the %var%'s with $var's
			foreach ( keys %tr ) {
				$res->{response} =~ s/%$_%/$tr{$_}/;
			}

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
#### END HACKERY

	undef %tr;
}

### I'm Spider Man, Bitch.
sub irc_bot_command {
	my ( $self, $kernel, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, KERNEL, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	my %tr = ( command => $cmd, nick => $nick, where => $where );
	$tr{args} = $args if defined $args;
	$tr{args_or_nick} = ( length($args) > 0 ) ? $args : $nick;

	if ( my $map = $self->getresponsemap($cmd) ) {
		if ( my $res = $self->getresponsefromkey( $map->{responsekey} ) ) {
			if ( defined $map->{args_regex} && defined $args ) {
				if ( $args =~ /$map->{args_regex}/ ) {

					#TODO find a better way of doing this
					$tr{arg0} = $1 || undef;
					$tr{arg1} = $2 || undef;
					$tr{arg2} = $3 || undef;
				} else {
					Lucy::debug( "Responses",
						"sendresponse: args didn't match the regex", 7 );
					return 0;
				}
			}

			# replace the %var%'s with $var's
			foreach ( keys %tr ) {
				$res->{response} =~ s/%$_%/$tr{$_}/;
			}

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

	undef %tr;
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

### Mmmm. We have been loaded.
sub new {
	return bless {}, shift;
}

1;
