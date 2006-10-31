#!/usr/bin/perl
# $Id: NickTrackar.pm 197 2006-05-13 18:50:53Z trevorj $
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
package Lucy::Diamonds::NickTrackar;
use POE;
use Switch;
use warnings;
use strict;
no strict 'refs';

# Oh yeah. We need a table name. and I'm so not typing it in a thousand times.
sub tablename             { return 'lucy_user_seen'; }
sub tablename_denora_user { return 'user'; }

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

### Bot command event
sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	if ( $cmd eq 'seen' ) {
		my $nick = ( split( /[@!]/, $who, 2 ) )[0];
		$where = $where->[0];
		Lucy::debug( "Trackar", "$nick asked for $args in $where", 6 );

		$lucy->privmsg( $where,
			Lucy::font( 'red', $nick ) . ": " . $self->getseen($args) );
		return 1;
	}
}

#
####
#### Someone has changed nicks
####
##TODO What should we do here exactly?
## Right now, it just updates the nick column with the new one
##  and then updates it's seen
## ^ SCRATCH THAT, IT DOES NOTHING
## Should we instead make a copy of the row with the nick changed, and
##  then update both rows' userseen to "nick(from|to)|($from|$to)"?
## Maybe thats too much.
## Find out whats in @hmm
## Should there be LIMIT 1 at the end of the query?
#sub irc_nick {
#	my ( $self, $lucy, $who, $to ) = @_[ OBJECT, SENDER, ARG0, ARG1 ];
#	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
#
#	#	$Lucy::dbh->query(
#	#		'UPDATE '
#	#		  . $self->tablename
#	#		  . ' SET nick = ?, seen = ?, ts = ? WHERE nick = ?',
#	#		$to, "nick|$nick|$to", time(), $nick
#	#	);
#	return 0;
#}

sub updateseen {
	my ( $self, $nick, $type ) = splice @_, 0, 3;

#TODO move this into a parsenick function, and use it in the subs, it shouldn't be in here
	$nick =~ s/^[\&\@\+\%\~ ]//;    #remove irc prefixen

	# remove |s, as we use them for delimiters; trim them while we're at it
	my @what;
	while ( my $t = shift ) {
		$t = Lucy::trim($t);
		$t =~ s/\|/:/g;
		push( @what, $t );
	}
	my $seen = "$type|" . join( '|', @what );
	undef @what;

	#print "saw $nick|$seen\n";
	if (
		my $d = $Lucy::dbh->select( $self->tablename_denora_user,
			['nickid'], { nick => lc($nick) } )->hash
	  )
	{
		my $ts = time;
		$Lucy::dbh->query(
			'REPLACE INTO '
			  . $self->tablename
			  . ' (id, nick, seen, ts) VALUES (?, ?, ?, ?)',
			$d->{nickid}, lc($nick), $seen, $ts
		);
	}

	# check if it's time to run the GC
	if (   ( !defined $self->{next_ttl_check} )
		|| ( $self->{next_ttl_check} < time ) )
	{
		Lucy::debug( "NickTrakar",
			"Running garbage collection on the seen table", 7 );
		$Lucy::dbh->query( 'DELETE FROM '
			  . $self->tablename
			  . ' WHERE '
			  . $self->tablename
			  . '.ts < (UNIX_TIMESTAMP(NOW())-259200)' );
	}

	# set the next ttl check time in about 5 minutes
	$self->{next_ttl_check} = time + 300;
}

###########################################
### Less Important Functions Go Here.
###
###

###
### Returns the seen for $nick as ()
###
sub getseen {
	my ( $self, $nick ) = @_;

	# Check if this user exist
	if (
		my $user =
		$Lucy::dbh->select( $self->tablename, [qw(id nick seen ts)],
			{ nick => lc($nick) } )->hash
	  )
	{
		my @seen      = split( /\|/, $user->{seen} );
		my $timesince = Lucy::timesince( $user->{ts} );

		switch ( $seen[0] ) {
			### msg states
			case 'pub' {
				return
"$nick was last seen saying '$seen[2]' in $seen[1] $timesince ago.";
			}
			case 'action' {
				return
"$nick was last seen in an action, with '* $nick $seen[2]' in $seen[1] $timesince ago.";
			}
			case 'join' {
				return "$nick was last seen joining $seen[1] $timesince ago.";
			}
			case 'part' {
				return "AFAIK, uber$nick parted $seen[1] $timesince ago.";
			}
			case 'quit' {
				return "$nick was last seen quitting irc $timesince ago.";
			}
			case 'kick' {
				return
"$nick was last seen being kicked out of $seen[1] by $seen[2] for $seen[3] $timesince ago.";
			}
			case 'topic' {
				return
"$nick was last seen changing the topic of $seen[1] to $seen[2] $timesince ago.";
			}
			else {
				$Lucy::lucy->privmsg(
					$Lucy::config->{Maintainer},
					'WTF MAN. My Seen DB is fucked up.'
				);
			}
		}

		# we shouldn't get here
		return 'wtf?';
	} else {
		return "Who the fuck is $nick?";
	}
}

1;
