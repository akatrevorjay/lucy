#!/usr/bin/perl
# SVN: $Id: MsgHandler.pm 202 2006-05-16 06:41:49Z trevorj $
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
package Lucy::MsgHandler;
use POE::Component::IRC::Plugin qw(:ALL);
use warnings;
use strict;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {
		cmd_regex => '
(?:nigga\s+)?
(?:when\s+)?
(?:have\s+|will\s+|can\s+)?
(?:you\s+)?
(?:please\s+)?
(?:tell me\s+)?
	(\w+)\s*
(?:for\s+)?
	(.*?)\s*[\?\!]*$'
	}, $class;
}

### Let's register some events
sub PCI_register {
	my ( $self, $lucy ) = splice @_, 0, 2;

	$lucy->plugin_register( $self, 'SERVER',
		qw(public msg 433 001 ctcp_time ctcp_userinfo ctcp_version) );
	return 1;
}

### We're being unloaded =(
sub PCI_unregister {
	my ( $self, $lucy ) = @_;
	return 1;
}

### Public message event
sub S_public {
	my ( $self, $lucy ) = splice @_, 0, 2;
	my ($who)     = ${ $_[0] };
	my ($where)   = ${ $_[1] };
	my ($what)    = ${ $_[2] };
	my ($botnick) = $lucy->nick_name();

	my ( $cmd, $args ) =
	  $what =~ /^(?:$botnick:\s+|$botnick,\s+|!)$self->{cmd_regex}/ix;
	if ($cmd) {
		$cmd = lc($cmd);
		Lucy::debug( "MsgHandler", "Sending irc_bot_command ($cmd,$args)", 7 );

		$lucy->_send_event( 'irc_bot_command', $who, $where, $what, $cmd, $args,
			'pub' );

		my %nick = parsenick($who);
		$where = $where->[0];
		$lucy->_send_event(
			'irc_bot_command_hash',
			$cmd,
			{
				who         => $who,
				where       => $where,
				nick        => $nick{nick},
				nick_status => $nick{status},
				what        => $what,
				cmd         => $cmd,
				args        => $args,
				type        => 'msg',
			},
		);
	}

	# Return an exit code
	return PCI_EAT_NONE;
}

# same as above but for private messages
sub S_msg {
	my ( $self, $lucy ) = splice @_, 0, 2;
	my ($who) = ${ $_[0] };

	#my ($where)   = ${ $_[1] };
	my ($what)    = ${ $_[2] };
	my ($botnick) = $lucy->nick_name();
	my $nick      = parsenick($who);
	my $where     = [$nick];

	my ( $cmd, $args ) = $what =~ /^!?$self->{cmd_regex}/iox;
	if ($cmd) {
		$cmd = lc($cmd);
		Lucy::debug( 'MsgHandler',
			"Sending privmsg irc_bot_command ($cmd,$args)", 7 );

		$lucy->_send_event( 'irc_bot_command', $who, $where, $what, $cmd, $args,
			'msg' );

		my %nick = parsenick($who);
		$where = $where->[0];
		$lucy->_send_event(
			'irc_bot_command_hash',
			$cmd,
			{
				who         => $who,
				where       => $where,
				nick        => $nick{nick},
				nick_status => $nick{status},
				what        => $what,
				cmd         => $cmd,
				args        => $args,
				type        => 'msg',
			},
		);
	}

	# Return an exit code
	return PCI_EAT_NONE;
}

# Ident to Nickserv, then join channels.
sub S_001 {
	my ( $self, $lucy ) = splice @_, 0, 2;

   # Ident to nickserv
   #TODO move this to S_msg, detect when it is needed by the message ns sends us
	if (   defined $Lucy::config->{NickServUser}
		&& defined $Lucy::config->{NickServPass}
		&& $lucy->nick_name() eq $Lucy::config->{Nick} )
	{
		Lucy::debug( "Connect",
			"Identifying with [" . $Lucy::config->{NickServUser} . "]", 6 );
		$lucy->yield(
			privmsg => $Lucy::config->{NickServUser},
			'IDENTIFY ' . $Lucy::config->{NickServPass}
		);
	}

	# oper if we are supposed to
	if (   defined $Lucy::config->{OperUser}
		&& defined $Lucy::config->{OperPass} )
	{
		Lucy::debug( "Connect", "IRCop as [" . $Lucy::config->{OperUser} . "]",
			6 );
		$lucy->yield(
			oper => $Lucy::config->{OperUser},
			$Lucy::config->{OperPass}
		);
	}
	foreach ( keys %{ $Lucy::config->{Channels} } ) {
		Lucy::debug( "Connect", "Joining [$_]", 4 );
		$lucy->yield( join => $_ );
	}
	return PCI_EAT_NONE;
}

# Change nick when it's in use
sub S_433 {
	my ( $self, $lucy ) = splice @_, 0, 2;

	# if we have a nickserv password, ghost the user
	if (   defined $Lucy::config->{NickServUser}
		&& defined $Lucy::config->{NickServPass} )
	{
		$lucy->yield(
			privmsg => $Lucy::config->{NickServUser},
			'GHOST '
			  . $Lucy::config->{Nick} . ' '
			  . $Lucy::config->{NickServPass}
		);
	}

	# just tack a random number at the end ( if we haven't yet that is )
	$lucy->yield( nick => $Lucy::config->{Nick} . $$ % 1000 )
	  unless $lucy->nick_name =~ /^$Lucy::config->{Nick}\d{1,4}$/;

	# try to change it again 10s later
	$lucy->delay( [ nick => $Lucy::config->{Nick} ], 10 );
	return PCI_EAT_NONE;
}

sub S_ctcp_version {
	my ( $self, $irc ) = splice @_, 0, 2;
	my $nick = ( split /!/, ${ $_[0] } )[0];
	Lucy::debug( "CTCP", "[$nick] VERSION", 5 );

	$irc->yield(
		ctcpreply => $nick => 'VERSION ' . ( "Lucy v" . $Lucy::VERSION ) );
	return PCI_EAT_NONE;
}

sub S_ctcp_time {
	my ( $self, $irc ) = splice @_, 0, 2;
	my $nick = ( split /!/, ${ $_[0] } )[0];
	Lucy::debug( "CTCP", "[$nick] TIME", 5 );

	$irc->yield(
		ctcpreply => $nick => strftime( "TIME %a %h %e %T %Y %Z", localtime ) );
	return PCI_EAT_NONE;
}

sub S_ctcp_userinfo {
	my ( $self, $irc ) = splice @_, 0, 2;
	my $nick = ( split /!/, ${ $_[0] } )[0];
	Lucy::debug( "CTCP", "[$nick] USERINFO", 5 );

	$irc->yield( ctcpreply => $nick => 'USERINFO '
		  . ( 'Lucy (Lucy Uses Clean Yarn) v' . $Lucy::VERSION ) );
	return PCI_EAT_NONE;
}

1;
