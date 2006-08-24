#!/usr/bin/perl
# SVN: $Id: State.pm 206 2006-05-19 03:51:55Z trevorj $
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
### State plugin TODO
#	- We need a way to do stats and shit in mysql by ourselves, without using denora's tables.
#	- Some of the code here was borrowed from PoCo::IRC::State
# We need to do it in mysql. Maybe a user system would be better... With a LRU cache of the users, etc
# Mmmmmm

###
### Lucy::Diamonds::State plugin. Manages users, channels, etc. Generally monitors
### whats going on.
###
package Lucy::Diamonds::State;
use POE;
use Switch;
use warnings;
use strict;

sub new {
	my $self = bless {}, shift;
	$self->init;
	return $self;
}

sub init {
	my $self = shift;

	#	$Lucy::lucy->add_event(
	#		qw(
	#		  irc_001
	#		  irc_315
	#		  irc_324
	#		  irc_352
	#		  irc_bot_msg
	#		  irc_bot_public
	#		  irc_ctcp_action
	#		  irc_disconnected
	#		  irc_error
	#		  irc_join
	#		  irc_kick
	#		  irc_mode
	#		  irc_msg
	#		  irc_nick
	#		  irc_part
	#		  irc_public
	#		  irc_quit
	#		  irc_socketerr
	#		  irc_topic
	#		  )
	#	);
}

sub log {
	my $self = shift;
	return undef unless defined $Lucy::lucy->{Diamonds}{Logger};
	return $Lucy::lucy->{Diamonds}{Logger}->log(@_);
}

sub updateseen {
	my $self = shift;
	return undef unless defined $Lucy::lucy->{Diamonds}{NickTrackar};
	return $Lucy::lucy->{Diamonds}{NickTrackar}->updateseen(@_);
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
	return 0;
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
	return 0;
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
	return 0;
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

	#$self->log( 'notices', "$nick: $what" );
	return 0;
}

###
### Called when Lucy sends a private messages
###
sub irc_bot_msg {
	my ( $self, $lucy, $where, $what ) = @_[ OBJECT, SENDER, ARG0, ARG1 ];
	my $who     = $where->[0];
	my $nick    = ( split( /[@!]/, $who, 2 ) )[0];
	my $botnick = $lucy->nick_name();

	unless ( $nick = $Lucy::config->{NickServUser} ) {
		Lucy::debug( "privmsg", "[$nick] $botnick: $what", 2 );
		$self->log( 'privmsg', "[$nick] $botnick: $what" );
	}
	return 0;
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
	return 0;
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
	return 0;
}

####
#### Called for CTCP::version
####TODO make this work damnit.
#sub irc_ctcp_version {
#	my ( $self, $lucy, $session, $who ) =
#	  @_[ OBJECT, SENDER, SESSION, ARG0 ];
#	return 0;
#}

#####
## This code borrows from PoCo::IRC::State heavily
##

# Event handlers for tracking the STATE. $lucy->{STATE} is used as our namespace.
# lc() is used to create unique keys.

# Make sure we have a clean STATE when we first join the network and if we inadvertently get disconnected
#TODO log these events as disconnected, etc
sub irc_001 {
	Lucy::debug( "IRC", "Connected.", 2 );

	#$_[OBJECT]->log('lucy','-!- IRC: Connected');
	delete $_[SENDER]->{state};
	return 0;
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

	# log it
	$self->log( $Lucy::config->{Channels}{$channel}{log},
		"-!- $nick joined $channel" );
	$self->updateseen( $nick, 'join', $channel );

	if ( lc($nick) eq lc( $lucy->nick_name ) ) {
		delete $lucy->{STATE}->{Chans}->{ lc($channel) };
		$lucy->{CHANNEL_SYNCH}->{ lc($channel) } = { MODE => 0, WHO => 0 };
		$kernel->yield( 'who'  => $channel );
		$kernel->yield( 'mode' => $channel );
	} else {
		$kernel->yield( 'who' => $nick );
		$lucy->{STATE}->{Nicks}->{ lc($nick) }->{Nick} = $nick;
		$lucy->{STATE}->{Nicks}->{ lc($nick) }->{User} = $user;
		$lucy->{STATE}->{Nicks}->{ lc($nick) }->{Host} = $host;
		$lucy->{STATE}->{Nicks}->{ lc($nick) }->{CHANS}->{ lc($channel) } = '';
		$lucy->{STATE}->{Chans}->{ lc($channel) }->{Nicks}->{ lc($nick) } = '';
	}

	return 0;
}

####
#### Someone has part
####
sub irc_part {
	my ( $kernel, $self, $lucy, $who ) = @_[ KERNEL, OBJECT, SENDER, ARG0 ];
	my $channel = lc $_[ARG1];
	my $nick = ( split /!/, $who )[0];
	Lucy::debug( "part", "$nick has left $channel", 2 );
	$self->log( $Lucy::config->{Channels}{$channel}{log},
		"-!- $nick left $channel" );
	$self->updateseen( $nick, 'part', $channel );

	$nick = lc($nick);
	if ( $nick eq lc( $lucy->nick_name() ) ) {
		delete $lucy->{STATE}->{Nicks}->{$nick}->{CHANS}->{$channel};
		delete $lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$nick};
		foreach
		  my $member ( keys %{ $lucy->{STATE}->{Chans}->{$channel}->{Nicks} } )
		{
			delete $lucy->{STATE}->{Nicks}->{$member}->{CHANS}->{$channel};
			if (
				scalar
				keys %{ $lucy->{STATE}->{Nicks}->{$member}->{CHANS} } <= 0 )
			{
				delete $lucy->{STATE}->{Nicks}->{$member};
			}
		}
		delete $lucy->{STATE}->{Chans}->{$channel};
	} else {
		delete $lucy->{STATE}->{Nicks}->{$nick}->{CHANS}->{$channel};
		delete $lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$nick};
		if ( scalar keys %{ $lucy->{STATE}->{Nicks}->{$nick}->{CHANS} } <= 0 ) {
			delete $lucy->{STATE}->{Nicks}->{$nick};
		}
	}
	return 0;
}

###
### Someone has quit ( yes this is different than part )
###
sub irc_quit {
	my ( $kernel, $self, $lucy, $who ) = @_[ KERNEL, OBJECT, SENDER, ARG0 ];
	my $nick = ( split /!/, $who )[0];
	Lucy::debug( "quit", "$nick has quit IRC", 2 );

#TODO find out what channels the user was on and log it
#$self->log( $Lucy::config->{Channels}{$channel}{log}, "-!- $nick has quit IRC" );
	$self->updateseen( $nick, 'quit' );

	$nick = lc($nick);
	if ( $nick eq lc( $Lucy::lucy->nick_name ) ) {
		delete $lucy->{STATE};
	} else {
		foreach
		  my $channel ( keys %{ $lucy->{STATE}->{Nicks}->{$nick}->{CHANS} } )
		{
			delete $lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$nick};
		}
		delete $lucy->{STATE}->{Nicks}->{$nick};
	}
	return 0;
}

###
### Someones been kicked
###
sub irc_kick {
	my ( $kernel, $self, $lucy, $channel, $nick, $reason ) =
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

	$nick    = lc($nick);
	$channel = lc($channel);
	if ( $nick eq lc( $Lucy::lucy->nick_name ) ) {
		delete $lucy->{STATE}->{Nicks}->{$nick}->{CHANS}->{$channel};
		delete $lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$nick};
		foreach
		  my $member ( keys %{ $lucy->{STATE}->{Chans}->{$channel}->{Nicks} } )
		{
			delete $lucy->{STATE}->{Nicks}->{$member}->{CHANS}->{$channel};
			if (
				scalar
				keys %{ $lucy->{STATE}->{Nicks}->{$member}->{CHANS} } <= 0 )
			{
				delete $lucy->{STATE}->{Nicks}->{$member};
			}
		}
		delete $lucy->{STATE}->{Chans}->{$channel};
	} else {
		delete $lucy->{STATE}->{Nicks}->{$nick}->{CHANS}->{$channel};
		delete $lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$nick};
		if ( scalar keys %{ $lucy->{STATE}->{Nicks}->{$nick}->{CHANS} } <= 0 ) {
			delete $lucy->{STATE}->{Nicks}->{$nick};
		}
	}
	return 0;
}

sub irc_disconnected {
	Lucy::Debug( 'IRC', 'Disconnected.', 2 );

	$_[OBJECT]->log( 'lucy', '-!- IRC: Disconnected' );
	delete $_[SENDER]->{state};
	return 0;
}

sub irc_error {
	Lucy::Debug( 'IRC', 'Error?', 2 );

	$_[OBJECT]->log( 'lucy', '-!- IRC: Error' );
	delete $_[SENDER]->{state};
	return 0;
}

sub irc_socketerr {
	Lucy::Debug( 'IRC', 'Socket error?', 2 );

	$_[OBJECT]->log( 'lucy', '-!- IRC: Socket error' );
	delete $_[SENDER]->{state};
	return 0;
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
# Find out whats in @hmm
# Should there be LIMIT 1 at the end of the query?
sub irc_nick {
	my ( $kernel, $self, $lucy, $who, $new ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];
	my $nick = ( split /!/, $who )[0];
	Lucy::debug( "nick", "$nick changed nicks to $new.", 2 );

	### log it
	$self->log( $Lucy::config->{Channels}{$_}{log},
		"-!- " . $nick . " changed nicks to [" . $new . "]" )
	  for $self->nick_channels($nick);

	### seen update
	#$Lucy::dbh->query(
	#	'UPDATE '
	#	  . $self->tablename_seen
	#	  . ' SET nick = ?, seen = ?, ts = ? WHERE nick = ?',
	#	$to, "nick|$nick|$to", time(), $nick
	#);

	#	if ( $nick eq $Lucy::lucy->nick_name ) {
	#		$Lucy::lucy->nick_name = $new;
	#	}

	$nick = lc($nick);
	if ( $nick eq lc($new) ) {

		# Case Change
		$lucy->{STATE}->{Nicks}->{$nick}->{Nick} = $new;
	} else {
		my $record = delete $lucy->{STATE}->{Nicks}->{$nick};
		$record->{Nick} = $new;
		foreach my $channel ( keys %{ $record->{CHANS} } ) {
			$lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$new} =
			  $record->{CHANS}->{$channel};
			delete $lucy->{STATE}->{Chans}->{$channel}->{Nicks}->{$nick};
		}
		$lucy->{STATE}->{Nicks}->{$new} = $record;
	}
	return 0;
}

# Channel MODE
sub irc_mode {
	my ( $kernel, $self, $lucy, $who, $channel ) =
	  @_[ KERNEL, OBJECT, SENDER, ARG0, ARG1 ];

	# Do nothing if it is UMODE
	if ( lc($channel) ne lc( $Lucy::lucy->nick_name ) ) {
		my $parsed_mode = $lucy->parse_mode_line( @_[ ARG2 .. $#_ ] );
		while ( my $mode = shift( @{ $parsed_mode->{modes} } ) ) {
			my ($arg);
			$arg = shift( @{ $parsed_mode->{args} } )
			  if ( $mode =~ /^(\+[hovklbIeaqfL]|-[hovbIeaq])/ );
			Lucy::debug( "mode", "$channel| got mode $mode", 4 );

		  SWITCH: {
				if ( $mode =~ /\+([ohvaq])/ ) {
					my ($flag) = $1;
					unless ( $lucy->{STATE}->{Nicks}->{ lc($arg) }->{CHANS}
						->{ lc($channel) } =~ /$flag/ )
					{
						$lucy->{STATE}->{Nicks}->{ lc($arg) }->{CHANS}
						  ->{ lc($channel) } .= $flag;
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{Nicks}
						  ->{ lc($arg) } =
						  $lucy->{STATE}->{Nicks}->{ lc($arg) }->{CHANS}
						  ->{ lc($channel) };
					}
					last SWITCH;
				}
				if ( $mode =~ /-([ohvaq])/ ) {
					my ($flag) = $1;
					if ( $lucy->{STATE}->{Nicks}->{ lc($arg) }->{CHANS}
						->{ lc($channel) } =~ /$flag/ )
					{
						$lucy->{STATE}->{Nicks}->{ lc($arg) }->{CHANS}
						  ->{ lc($channel) } =~ s/$flag//;
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{Nicks}
						  ->{ lc($arg) } =
						  $lucy->{STATE}->{Nicks}->{ lc($arg) }->{CHANS}
						  ->{ lc($channel) };
					}
					last SWITCH;
				}
				if ( $mode =~ /[bIefL]/ ) {
					last SWITCH;
				}
				if ( $mode eq '+l' and defined($arg) ) {
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} .= 'l'
					  unless (
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~
						/l/ );
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{ChanLimit} =
					  $arg;
					last SWITCH;
				}
				if ( $mode eq '+k' and defined($arg) ) {
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} .= 'k'
					  unless (
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~
						/k/ );
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{ChanKey} = $arg;
					last SWITCH;
				}
				if ( $mode eq '-l' ) {
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~ s/l//;
					delete( $lucy->{STATE}->{Chans}->{ lc($channel) }
						  ->{ChanLimit} );
					last SWITCH;
				}
				if ( $mode eq '-k' ) {
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~ s/k//;
					delete(
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{ChanKey} );
					last SWITCH;
				}

	  # Anything else doesn't have arguments so just adjust {Mode} as necessary.
				if ( $mode =~ /^\+(.)/ ) {
					my ($flag) = $1;
					$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} .= $flag
					  unless (
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~
						/$flag/ );
					last SWITCH;
				}
				if ( $mode =~ /^-(.)/ ) {
					my ($flag) = $1;
					if ( $lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~
						/$flag/ )
					{
						$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~
						  s/$flag//;
					}
					last SWITCH;
				}
			}
		}

		# Lets make the channel mode nice
		if ( $lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} ) {
			$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} = join(
				'',
				sort { uc $a cmp uc $b } (
					split(
						//, $lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode}
					)
				)
			);
		} else {
			delete( $lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} );
		}
	}
	return 0;
}

# RPL_WHOREPLY
sub irc_352 {
	my ( $kernel, $self, $lucy ) = @_[ KERNEL, OBJECT, SENDER ];
	my ( $first, $second ) = split( / :/, $_[ARG1] );
	my ( $channel, $user, $host, $server, $nick, $status ) =
	  split( / /, $first );
	my ($real) = substr( $second, index( $second, " " ) + 1 );
	Lucy::debug( "IRC", "$channel| got who reply for $nick", 6 );

	$lucy->{STATE}->{Nicks}->{ lc($nick) }->{Nick}   = $nick;
	$lucy->{STATE}->{Nicks}->{ lc($nick) }->{User}   = $user;
	$lucy->{STATE}->{Nicks}->{ lc($nick) }->{Host}   = $host;
	$lucy->{STATE}->{Nicks}->{ lc($nick) }->{Real}   = $real;
	$lucy->{STATE}->{Nicks}->{ lc($nick) }->{Server} = $server;
	if ( $channel ne '*' ) {
		my ($whatever) = '';
		if ( $status =~ /\@/ ) { $whatever = 'o'; }
		if ( $status =~ /\+/ ) { $whatever = 'v'; }
		if ( $status =~ /\%/ ) { $whatever = 'h'; }
		if ( $status =~ /\&/ ) { $whatever = 'a'; }
		if ( $status =~ /\~/ ) { $whatever = 'q'; }
		$lucy->{STATE}->{Nicks}->{ lc($nick) }->{CHANS}->{ lc($channel) } =
		  $whatever;
		$lucy->{STATE}->{Chans}->{ lc($channel) }->{Name} = $channel;
		$lucy->{STATE}->{Chans}->{ lc($channel) }->{Nicks}->{ lc($nick) } =
		  $whatever;
	}
	if ( $status =~ /\*/ ) {
		$lucy->{STATE}->{Nicks}->{ lc($nick) }->{IRCop} = 1;
	}
	return 0;
}

#RPL_ENDOFWHO
sub irc_315 {
	my ( $kernel, $self, $lucy ) = @_[ KERNEL, OBJECT, SENDER ];
	my ($channel) = ( split / :/, $_[ARG1] )[0];
	Lucy::debug( "IRC", "$channel| got end of who", 6 );

	# If it begins with #, &, + or ! its a channel apparently. RFC2812.
	if ( $channel =~ /^[\x23\x2B\x21\x26]/ ) {
		$self->_channel_sync_who($channel);
		if ( $self->_channel_sync($channel) ) {
			delete( $self->{CHANNEL_SYNCH}->{ lc($channel) } );
			$self->_send_event( 'irc_chan_sync', $channel );
		}

		# Otherwise we assume its a nickname
	} else {
		$self->_send_event( 'irc_nick_sync', $channel );
	}
	return 0;
}

# RPL_CHANNELMODEIS
sub irc_324 {
	my ( $kernel, $self, $lucy ) = @_[ KERNEL, OBJECT, SENDER ];
	my (@args)    = split( / /, $_[ARG1] );
	my ($channel) = shift @args;

	my ($parsed_mode) = $lucy->parse_mode_line(@args);
	Lucy::debug( "IRC",
		"got $channel mode [" . @{ $parsed_mode->{modes} } . "]", 5 );

	while ( my $mode = shift( @{ $parsed_mode->{modes} } ) ) {
		$mode =~ s/\+//;
		my ($arg);
		$arg = shift( @{ $parsed_mode->{args} } ) if ( $mode =~ /[kl]/ );
		$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} .= $mode
		  unless (
			$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} =~ /$mode/ );
		if ( $mode eq 'l' and defined($arg) ) {
			$lucy->{STATE}->{Chans}->{ lc($channel) }->{ChanLimit} = $arg;
		}
		if ( $mode eq 'k' and defined($arg) ) {
			$lucy->{STATE}->{Chans}->{ lc($channel) }->{ChanKey} = $arg;
		}
	}
	if ( $lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} ) {
		$lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} = join(
			'',
			sort { uc $a cmp uc $b } (
				split( //, $lucy->{STATE}->{Chans}->{ lc($channel) }->{Mode} )
			)
		);
	}
	$lucy->_channel_sync_mode($channel);
	if ( $lucy->_channel_sync($channel) ) {
		delete( $lucy->{CHANNEL_SYNCH}->{ lc($channel) } );
		$lucy->_send_event( 'irc_chan_sync', $channel );
	}
	return 0;
}

1;

###
### Lucy::User is our User object. It just provides easy access to a user's information.
### Also uses that nifty Lucy::GenericObject ;)
#package Lucy::User;
#use warnings;
#use strict;
#our @ISA = qw(Lucy::GenericObject);
#
#sub _init {
#	my $self = shift;
#	map { $self->{fields}{$_} = 1; }, [qw(prefix nick username ircname host umode)];
#}
#
#sub mask {
#	my $self = shift;
#	unless ( defined $self->{nick}
#		&& defined $self->{username}
#		&& defined $self->{host} )
#	{
#		Lucy::debug( 'User', 'Asked for mask without nick+username+host??', 4 );
#		return 0;
#	}
#	return $self->{nick} . '!' . $self->{username} . '@' . $self->{host};
#}
#
#1;

