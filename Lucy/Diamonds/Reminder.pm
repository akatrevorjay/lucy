#!/usr/bin/perl
# SVN: $Id: Reminder.pm 207 2006-05-19 06:08:23Z trevorj $
# ____________
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
#TODO add garbage collection
package Lucy::Diamonds::Reminder;
use POE;
use strict;
use warnings;

sub tablename { return 'lucy_reminders'; }

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

### Public message event
sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	# Only works with fixed SQL::Abstract [w/ mysql 5]
	my ( $to, $reminder );
	if (   ( $cmd eq 'remind' )
		&& ( ( $to, $reminder ) = $args =~ /^(\w{3,30})\s*(.+)$/ ) )
	{
		$Lucy::dbh->insert( $self->tablename,
			{ from => $nick, to => lc($to), reminder => $reminder, ts => time }
		);
		$lucy->privmsg( $where,
			Lucy::font( 'darkred', $nick ) . ": ok, saving reminder for $to" );
		return 1;
	} elsif ( ( $cmd eq 'unremind' )
		&& ( ($to) = $args =~ /^(\w{3,30})$/ ) )
	{
		$Lucy::dbh->delete( $self->tablename,
			{ from => $nick, to => lc($to) } );
		$lucy->privmsg( $where,
			Lucy::font( 'darkred', $nick )
			  . ": ok, I removed all reminders from you to $to" );
		return 1;
	}
}

sub check_for_reminders {
	my ( $self, $nick, $lucy, $where ) = @_;

	my $q =
	  $Lucy::dbh->select( $self->tablename, [qw(id from reminder ts)],
		{ to => lc($nick) } )
	  or return;
	for my $r ( $q->hashes ) {
		my $timesince = Lucy::timesince( $r->{ts} );
		$timesince
		  ? $timesince =
		  ' around ' . $timesince . ' ago'
		  : $timesince = '';
		$lucy->privmsg( $where,
			Lucy::font( 'darkred', $nick )
			  . ": $r->{from} wanted to remind you $r->{reminder}$timesince" );
		$Lucy::dbh->delete( $self->tablename, { id => $r->{id} } );
	}
}

###
### Someone has joined
###
sub irc_join {
	my ( $self, $lucy, $who, $where ) = @_[ OBJECT, SENDER, ARG0, ARG1 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$self->check_for_reminders( $nick, $lucy, $where );
	return 0;
}

###
### Someone has said something
###
sub irc_public {
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	$self->check_for_reminders( $nick, $lucy, $where );
	return 0;
}

1;
