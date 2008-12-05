#!/usr/bin/perl
# SVN: $Id$
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
use base qw(Lucy::Diamond);
use POE;
use strict;
use warnings;

sub tablename { return 'lucy_reminders'; }

sub commands {
	return {
		remind   => [qw(remind)],
		unremind => [qw(unremind)],
	};
}

sub remind {
	my ( $self, $v ) = @_;

	# Only works with fixed SQL::Abstract [w/ mysql 5]
	my ( $to, $reminder );
	if ( ( $to, $reminder ) = $v->{args} =~ /^([\w\-\_\']{3,30})\s*(.+)$/ ) {
		$Lucy::dbh->insert(
			$self->tablename,
			{
				from     => $v->{nick},
				to       => lc($to),
				reminder => $reminder,
				ts       => time
			}
		);
		$Lucy::lucy->privmsg( $v->{where},
			Lucy::font( 'darkred', $v->{nick} )
			  . ": ok, saving reminder for $to" );
		return 1;
	}
}

sub unremind {
	my ( $self, $v ) = @_;

	# Only works with fixed SQL::Abstract [w/ mysql 5]
	my ($to);
	if ( ($to) = $v->{args} =~ /^([\w\-\_\']{3,30})$/ ) {
		$Lucy::dbh->delete( $self->tablename,
			{ from => $v->{nick}, to => lc($to) } );
		$Lucy::lucy->privmsg( $v->{where},
			Lucy::font( 'darkred', $v->{nick} )
			  . ": ok, I removed all reminders from you to $to" );
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
		  ? $timesince = ' around ' . $timesince . ' ago'
		  : $timesince = '';
		$lucy->privmsg( $where,
			Lucy::font( 'darkred', $nick )
			  . ": $r->{from} wanted to remind you $r->{reminder}$timesince" );
		$Lucy::dbh->delete( $self->tablename, { id => $r->{id} } );
	}
}

#TODO cleanup
sub count_reminders {
	my ( $self, $nick, $where ) = @_;

	my $q = $Lucy::dbh->query(
		'SELECT COUNT(*) FROM ' . $self->tablename . ' AS r WHERE r.to = ?',
		lc($nick) )
	  or return;

	my ($rcount) = $q->list;
	unless ( defined $rcount && $rcount >= 0 ) {
		$rcount = 0;
	}

	return $rcount;
}

###
### Someone has joined
###
sub irc_join {
	my ( $self, $lucy, $who, $where ) = @_[ OBJECT, SENDER, ARG0, ARG1 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];

	my $rcount = $self->count_reminders( $nick, $where );
	$lucy->yield( privmsg => $where =>
		  "$nick: You have $rcount reminder(s) available. Tell me you love me."
	) if ( $rcount > 0 );

	#	$self->check_for_reminders( $nick, $lucy, $where, 0 );
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
