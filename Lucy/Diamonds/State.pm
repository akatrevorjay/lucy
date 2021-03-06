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
### State plugin ChangeLog
#	- trevorj: I removed all of the old state code, and used PoCo::IRC::State again. I hate the way it stores
#		the STATE, but the code here wasn't making any progress either, so until we make a layer around denora,
#		this is the best way to do it IMO
#
### State plugin TODO
#	- trevorj: I want to rely heavily on denora's tables for the state. If this means a requirement
#		of denora, then so be it. Why should we re-create whats already done for us?
#
# We need to do it in mysql. Maybe a user system would be better... With a LRU cache of the users, etc
# Mmmmmm

###
### Lucy::Diamonds::State plugin. Manages users, channels, etc. Generally monitors
### whats going on.
###
package Lucy::Diamonds::State;
use base qw(Lucy::Diamond);
use POE;
use Switch;
use warnings;
use strict;

sub new {
	my $self = bless { priority => 0 }, shift;
	return $self;
}

# Logger->log hook
sub log {
	my $self = shift;

	#TODO does this fix the weird irc_public bug?
	# apparently, perl returns the last sub's return value if you call it. wtf?
	$Lucy::lucy->{Diamonds}{Logger}->log(@_)
	  if ( $Lucy::lucy->is_diamond_loaded('Logger') );
	return undef;
}

# NickTrackar->updateseen hook
sub updateseen {
	my $self = shift;

	#TODO does this fix the weird irc_public bug?
	# apparently, perl returns the last sub's return value if you call it. wtf?
	$Lucy::lucy->{Diamonds}{NickTrackar}->updateseen(@_)
	  if ( defined $Lucy::lucy->is_diamond_loaded('NickTrackar') );
	return undef;
}

###
### Called for CTCP::action
###
sub irc_ctcp_action {
	my ( $self, $lucy, $session, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, SESSION, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	Lucy::debug( 'action', "$where|* $nick $what", 2 );

	$self->log( $Lucy::config->{Channels}{$where}{log}, "* $nick $what" );
	$self->updateseen( $nick, 'action', $where, $what );
}

###
### OOooo a public message treasha?
###
sub irc_public {
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	$where = $where->[0];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	Lucy::debug( "public", "$where |<$nick> $what", 4 );

	$self->log( $Lucy::config->{Channels}{$where}{log}, "<$nick> $what" );
	$self->updateseen( $nick, 'pub', $where, $what );
}

###
### Called for private messages
###
sub irc_msg {
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	Lucy::debug( "privmsg", "[$nick] $nick: $what", 2 );
	$self->log( 'privmsg', "[$nick] $nick: $what" );
}

###
### Called for private messages
###
sub irc_notice {
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	Lucy::debug( "notice", "$nick|$nick: $what", 8 );

	#$self->log( 'notice', "$nick: $what" );
}

###
### Called when Lucy sends a private messages
###
sub irc_bot_msg {
	my ( $self, $lucy, $who, $what ) = @_[ OBJECT, SENDER, ARG0, ARG1 ];
	$who = $who->[0];
	my $nick    = Lucy::parsenick($who);
	my $botnick = $lucy->nick_name();

	unless ( $nick eq $Lucy::config->{NickServUser} ) {
		Lucy::debug( "privmsg", "[$nick] $botnick: $what", 2 );
		$self->log( 'privmsg', "[$nick] $botnick: $what" );
	}
}

###
### Called when Lucy sends a public message in a channel
###
sub irc_bot_public {
	my ( $self, $lucy, $where, $what ) = @_[ OBJECT, SENDER, ARG0, ARG1 ];
	$where = $where->[0];
	my $nick = $lucy->nick_name();
	Lucy::debug( "public", "$where |<$nick> $what", 4 );

	$self->log( $Lucy::config->{Channels}{$where}{log}, "<$nick> $what" );
}

###
### Someone has changed the topic
###
sub irc_topic {
	my ( $self, $lucy, $who, $channel, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	Lucy::debug( "topic", "$nick changed the topic of $channel to: $what", 4 );

	$self->log( $Lucy::config->{Channels}{$channel}{log},
		"-!- $nick changed the topic of $channel to [$what]" );
}

####
#### Called for CTCP::version
####TODO make this work damnit.
#sub irc_ctcp_version {
#	my ( $self, $lucy, $session, $who ) =
#	  @_[ OBJECT, SENDER, SESSION, ARG0 ];
##}

#TODO log these events as disconnected, etc
sub irc_001 {
	Lucy::debug( "IRC", "Connected.", 2 );

	#$_[OBJECT]->log('lucy','-!- IRC: Connected');
}

###
### Someone has joined
###
sub irc_join {
	my ( $kernel, $self, $lucy, $who, $channel ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
	my $nick     = ( split /!/, $who )[0];
	my $userhost = ( split /!/, $who )[1];
	my ( $user, $host ) = split( /\@/, $userhost );
	Lucy::debug( "join", "$nick has joined $channel", 2 );

	# log n seen
	$self->log( $Lucy::config->{Channels}{$channel}{log},
		"-!- $nick joined $channel" );
	$self->updateseen( $nick, 'join', $channel );
}

###
### respond to invitations
### TODO: this should really not go in this module!
###
sub irc_invite {

	# stuff echoline doesn't understand.  HELP! CLEAN UP!
	my ( $kernel, $self, $lucy, $who, $channel ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
	my $nick     = ( split /!/, $who )[0];
	my $userhost = ( split /!/, $who )[1];
	my ( $user, $host ) = split( /\@/, $userhost );
	Lucy::debug( "invite", "$nick has invited me to $channel", 2 );

	# add channel to config, join, and log.
	$Lucy::config->{Channels}{$channel} = { log => "$channel.log", };
	$lucy->yield( join => $channel );
	$self->log(
		$Lucy::config->{Channels}{$channel}{log},
		"-!- invited to $channel by $nick"
	);
}

####
#### Someone has part
####
sub irc_part {
	my ( $kernel, $self, $lucy, $who ) = @_[ KERNEL, OBJECT, SENDER, ARG0 ];
	my $channel = lc $_[ARG1];
	my $nick = ( split /!/, $who )[0];
	Lucy::debug( "part", "$nick has left $channel", 2 );

	# log n seen
	$self->log( $Lucy::config->{Channels}{$channel}{log},
		"-!- $nick left $channel" );
	$self->updateseen( $nick, 'part', $channel );

	if ( $nick eq $lucy->nick_name ) {
		Lucy::debug( "part", "Rejoining $channel in 5s because I was parted",
			2 );
		$lucy->delay( [ join => $channel ], 5 );
	}
}

###
### Someone has quit ( yes this is different than part )
###
#FUCK ARG2 is provided by PoCo::IRC::State
sub irc_quit {
	my ( $kernel, $self, $lucy, $who, $channels ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG2 ];
	my $nick = ( split /!/, $who )[0];
	Lucy::debug( "quit", "$nick has quit IRC", 2 );

	# find out what channels the user was on and log it
	foreach ( @{$channels} ) {
		$self->log( $Lucy::config->{Channels}{$_}{log},
			"-!- $nick has quit IRC" );
	}
	$self->updateseen( $nick, 'quit' );
}

###
### Someones been kicked
###
#FUCK ARG4 is provided by PoCo::IRC::State
sub irc_kick {
	my ( $kernel, $self, $lucy, $channel, $nick, $reason, $mask ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG1, ARG2, ARG3 ];
	my $kicker = ( split( /[@!]/, $_[ARG0], 2 ) )[0];
	Lucy::debug( "kick",
		"$nick has been kicked from $channel by $kicker for [$reason]", 2 );

	# log it
	$self->log(
		$Lucy::config->{Channels}{$channel}{log},
		"-!- " . $nick . " has quit [" . $channel . "]"
	);
	$self->updateseen( $nick, 'kick', $channel, $kicker, $reason );

	#TODO move to MsgHandler
	if ( $nick eq $lucy->nick_name ) {
		Lucy::debug( "kick", "Rejoining $channel in 5s because I was kicked",
			2 );
		$lucy->delay( [ join => $channel ], 5 );
	}
}

###
### We're banned from a channel
###
sub irc_474 {
	my ( $kernel, $self, $lucy, $server, $args ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG2 ];
	my ( $where, $msg ) = @$args;

	Lucy::debug( "banned", "Banned from channel [$where] [$msg]", 1 );

	#TODO move to MsgHandler
	if (   defined $Lucy::config->{OperUser}
		&& defined $Lucy::config->{OperPass} )
	{
		Lucy::debug( "banned", "SAJoining [$where] in 5s because I was banned",
			1 );
		$lucy->delay(
			[ quote => sajoin => " " . $lucy->nick_name . " :" . $where ], 5 );
	}

	#$_[OBJECT]->log('lucy','-!- IRC: Cannot join [$where]. Banned. [$msg]');
}

sub irc_disconnected {
	Lucy::debug( 'IRC', 'Disconnected.', 2 );

	$_[OBJECT]->log( 'lucy', '-!- IRC: Disconnected' );
}

sub irc_error {
	Lucy::debug( 'IRC', 'Error?', 2 );

	$_[OBJECT]->log( 'lucy', '-!- IRC: Error' );
}

sub irc_socketerr {
	Lucy::debug( 'IRC', 'Socket error?', 2 );

	$_[OBJECT]->log( 'lucy', '-!- IRC: Socket error' );
}

###
### Someone has changed nicks
###
#TODO What should we do here exactly?
# Right now, it just updates the nick column with the new one
#  and then updates it's seen
# ^ SCRATCH THAT, IT DOES NOTHING
# Should we instead make a copy of the row with the nick changed, and
#  then update both rows' userseen to "nick(from|to)|($from|$to)"?
# Maybe thats too much.
# Should there be LIMIT 1 at the end of the query?
sub irc_nick {
	my ( $kernel, $self, $lucy, $who, $new ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
	my $nick = ( split /!/, $who )[0];
	Lucy::debug( "nick", "$nick changed nicks to $new.", 2 );

	### log it
	foreach (
		eval {
			     @{ $lucy->nick_channels($new) }
			  || @{ $lucy->nick_channels($new) }
			  || [];
		}
	  )
	{
		$self->log( $Lucy::config->{Channels}{$_}{log},
			"-!- " . $nick . " changed nicks to [" . $new . "]" );
	}

	### seen update
	#$Lucy::dbh->query(
	#	'UPDATE '
	#	  . $self->tablename_seen
	#	  . ' SET nick = ?, seen = ?, ts = ? WHERE nick = ? LIMIT 1',
	#	$to, "nick|$nick|$to", time(), $nick
	#);

	#if ( $nick eq $Lucy::lucy->nick_name ) {
	#	$Lucy::lucy->nick_name = $new;
	#}
}

## Channel MODE
#sub irc_mode {
#	my ( $kernel, $self, $lucy, $who, $channel ) =
#	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
##}

## RPL_WHOREPLY
#sub irc_352 {
#	my ( $kernel, $self, $lucy ) = @_[ KERNEL, OBJECT, SENDER ];
#	my ( $first, $second ) = split( / :/, $_[ARG1] );
#	my ( $channel, $user, $host, $server, $nick, $status ) =
#	  split( / /, $first );
#	my ($real) = substr( $second, index( $second, " " ) + 1 );
#	Lucy::debug( "IRC", "$channel| got who reply for $nick", 8 );
#
##}

##RPL_ENDOFWHO
#sub irc_315 {
#	my ( $kernel, $self, $lucy ) = @_[ KERNEL, OBJECT, SENDER ];
#	my ($channel) = ( split / :/, $_[ARG1] )[0];
#	Lucy::debug( "IRC", "$channel| got end of who", 7 );
##}

## RPL_CHANNELMODEIS
#sub irc_324 {
#	my ( $kernel, $self, $lucy ) = @_[ KERNEL, OBJECT, SENDER ];
#	my (@args)    = split( / /, $_[ARG1] );
#	my ($channel) = shift @args;
#
#	Lucy::debug( "IRC", "got $channel mode [" . 'fixme' . "]", 5 );
##}

1;
