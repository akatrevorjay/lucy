#!/usr/bin/perl
# SVN: $Id: Sky.pm 198 2006-05-14 02:09:33Z trevorj $
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
#  This was originally based on Bot::Pluggable and PoCo::IRC::Object. Both were b0rk.
#  I read the Artistic License and I think I can do this, but IANAL. They are found here:
#  http://search.cpan.org/dist/(Bot-Pluggable|POE-Component-IRC-Object)/, so kudos to their author.
package Lucy::Sky;
use POE
  qw(Component::IRC Component::IRC::Plugin::BotTraffic Component::IRC::Plugin::Connector Component::IRC::Plugin::ISupport);
use Lucy::MsgHandler;
use again;
use warnings;
use strict;
no strict 'refs';
use vars qw($AUTOLOAD);

###
### Diamond stuff
###
#$self->{Diamonds}{$d}->_unload();
#TODO with a hash of objects, how would I do priorities?
sub add_diamond {
	my $self = shift;
	foreach my $d (@_) {
		if ( eval { return require_again( 'Lucy::Diamonds::' . $d ) or undef; }
		  )
		{
			$self->remove_diamond($d) if $self->is_diamond_loaded($d);
			$self->{Diamonds}{$d} =
			  eval( 'return Lucy::Diamonds::' . $d . '->new() or undef;' );
			Lucy::debug( "Sky", "Loaded diamond $d", 2 );
		} else {
			Lucy::debug( "Sky",
				"WHOA THERE NELLY!!! $d failed to load: \n" . $@, 1 );
		}
	}
}

sub remove_diamond {
	my $self = shift;
	foreach my $d (@_) {
		if ( $self->is_diamond_loaded($d) ) {
			delete $self->{Diamonds}{$d};
			Lucy::debug( "Sky", "Unloaded diamond $d", 2 );
		} else {
			Lucy::debug( "Sky",
				"WHOA THERE NELLY!!! $d failed to unload: \n" . $@, 1 );
		}
	}
}

#TODO if run without args, reload all modules OR preferably, reload all changed modules
sub reload_diamond {
	my ( $self, @diamonds ) = @_;
	$self->remove_diamond(@diamonds);
	$self->add_diamond(@diamonds);
}

sub is_diamond_loaded {
	my ( $self, $diamond ) = @_;
	return ( defined $self->{Diamonds}{$diamond} ) ? 1 : undef;
}

sub add_event {
	my $self = shift;
	while ( my $method = shift ) {
		$self->{Events}{$method} = 1 unless defined $self->{Events}{$method};
	}
}

###
### IRC
###
# Some of this was borrowed from PoCo::IRC::Object

sub new {
	my $class = shift;
	die __PACKAGE__ . "->new() params must be a hash" if @_ % 2;
	my %params = @_;

	my $self = bless \%params, $class;
	$self->init();
	return $self;
}

sub init {
	my ($self) = @_;

	# Create the component that will represent an IRC network.
	$self->{__irc} =
	  POE::Component::IRC->spawn(
		Debug => ( $Lucy::config->{debug_level} >= 8 ) ? 1 : 0 );

	POE::Session->create(
		object_states => [ $self => [ '_start', '_stop', '_default' ], ], );
}

sub _start {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

	$self->{__irc}->plugin_add( 'MsgHandler' => Lucy::MsgHandler->new() );
	$self->{__irc}->plugin_add( 'BotTraffic',
		POE::Component::IRC::Plugin::BotTraffic->new() );
	$self->{__irc}->plugin_add(
		'Connector' => POE::Component::IRC::Plugin::Connector->new() );
	$self->{__irc}->plugin_add(
		'ISupport' => POE::Component::IRC::Plugin::ISupport->new() );
	$self->{__irc}->yield( "register", "all" );

	my $hash = {};
	$hash->{Server} = $Lucy::config->{Server}
	  || 'pool.intheskywithdiamonds.net';
	$hash->{Port}     = $Lucy::config->{Port}     || 6667;
	$hash->{Nick}     = $Lucy::config->{Nick}     || 'lamerlucile';
	$hash->{Username} = $Lucy::config->{Username} || 'lucy';
	$hash->{Ircname}  = $Lucy::config->{Ircname}  || 'My Owner is a Lamer';
	$hash->{UseSSL}   = $Lucy::config->{UseSSL}   || undef;

	$self->{__irc}->yield( "connect" => $hash );
	undef $hash;
}

sub _stop {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

	Lucy::debug( 'IRC', 'Quitting...', 0 );
	$self->{__Quitting} = 1;
	$self->{__irc}->yield('quit');
}

sub _default {
	my ( $self, $kernel, $state, $args ) = @_[ OBJECT, KERNEL, ARG0, ARG1 ];

	$_[SENDER] = $self;
	my @new_ = @_[ 1 .. ( ARG0- 1 ) ];
	push @new_, @$args;

	# run it on Sky if we can
	$self->$state(@new_) if $self->can($state);

	# run the event on the diamonds
	if ( $self->{Events}{$state} ) {
		foreach my $d ( keys %{ $self->{Diamonds} } ) {
			my $meth = $self->{Diamonds}{$d}->can($state);
			next unless $meth;
			my $ret = eval { $meth->( $self->{Diamonds}{$d}, @new_ ) };
			Lucy::debug( 'Sky',
				'Compilation of ' . $state . ' @ ' . $d . ' failed: ' . $@, 0 )
			  if $@;
			return if $ret;
		}
	}
	return 0;
}

sub AUTOLOAD {
	my $self   = shift;
	my $method = $AUTOLOAD;
	$method =~ s/^.*://;

	#print "\ntrevorj: I caught a fish! $method\n\n";
	my $ret;
	if ( $self->{__irc}->can($method) ) {
		$ret = eval { $self->{__irc}->$method(@_); };
		Lucy::debug( 'Sky',
			'Compilation of ' . $method . ' @ Sky:AUTOLOAD_can failed: ' . $@,
			0 )
		  if $@;
	} else {
		$ret = eval { $self->{__irc}->call( $method, @_ ); };
		Lucy::debug(
			'Sky',
			'Compilation of ' . $method . ' @ Sky:AUTOLOAD_else failed: ' . $@,
			0
		  )
		  if $@;
	}
	return $ret;
}

##########
# Methods for state query
# Internal methods begin with '_'
#

sub _channel_sync {
	my ($self) = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	return 0 unless $self->_channel_exists($channel);

	if ( defined( $self->{CHANNEL_SYNCH}->{$channel} ) ) {
		if (    $self->{CHANNEL_SYNCH}->{$channel}->{MODE}
			and $self->{CHANNEL_SYNCH}->{$channel}->{WHO} )
		{
			return 1;
		}
	}
	return 0;
}

sub _channel_sync_mode {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;

	unless ( $self->_channel_exists($channel) ) {
		return 0;
	}

	if ( defined( $self->{CHANNEL_SYNCH}->{$channel} ) ) {
		$self->{CHANNEL_SYNCH}->{$channel}->{MODE} = 1;
		return 1;
	}
	return 0;
}

sub _channel_sync_who {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;

	unless ( $self->_channel_exists($channel) ) {
		return 0;
	}

	if ( defined( $self->{CHANNEL_SYNCH}->{$channel} ) ) {
		$self->{CHANNEL_SYNCH}->{$channel}->{WHO} = 1;
		return 1;
	}
	return 0;
}

sub _nick_exists {
	my ($self) = shift;
	my ($nick) = lc( $_[0] ) || return 0;

	if ( defined( $_[SENDER]->{state}->{Nicks}->{$nick} ) ) {
		return 1;
	}
	return 0;
}

sub _channel_exists {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;

	if ( defined( $_[SENDER]->{state}->{Chans}->{$channel} ) ) {
		return 1;
	}
	return 0;
}

sub _nick_has_channel_mode {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;
	my ($flag)    = ( split //, $_[2] )[0] || return 0;

	unless ( $self->is_channel_member( $channel, $nick ) ) {
		return 0;
	}

	if ( $_[SENDER]->{state}->{Nicks}->{$nick}->{CHANS}->{$channel} =~ /$flag/ )
	{
		return 1;
	}
	return 0;
}

# Returns all the channels that the bot is on with an indication of whether it has operator, halfop or voice.
sub channels {
	my ($self) = shift;
	my (%result);
	my ($realnick) = lc( $Lucy::lucy->nick_name );

	if ( $self->_nick_exists($realnick) ) {
		foreach my $channel (
			keys %{ $_[SENDER]->{state}->{Nicks}->{$realnick}->{CHANS} } )
		{
			$result{ $_[SENDER]->{state}->{Chans}->{$channel}->{Name} } =
			  $_[SENDER]->{state}->{Nicks}->{$realnick}->{CHANS}->{$channel};
		}
	}
	return \%result;
}

sub nicks {
	my ($self) = shift;
	my (@result);

	foreach my $nick ( keys %{ $_[SENDER]->{state}->{Nicks} } ) {
		push( @result, $_[SENDER]->{state}->{Nicks}->{$nick}->{Nick} );
	}
	return @result;
}

sub nick_info {
	my ($self) = shift;
	my ($nick) = lc( $_[0] ) || return 0;

	unless ( $self->_nick_exists($nick) ) {
		return 0;
	}

	my ($record) = $_[SENDER]->{state}->{Nicks}->{$nick};

	my (%result) = %{$record};

	$result{Userhost} = $result{User} . '@' . $result{Host};

	delete( $result{'CHANS'} );

	return \%result;
}

sub nick_long_form {
	my ($self) = shift;
	my ($nick) = lc( $_[0] ) || return 0;

	unless ( $self->_nick_exists($nick) ) {
		return 0;
	}

	my ($record) = $_[SENDER]->{state}->{Nicks}->{$nick};

	return $record->{Nick} . '!' . $record->{User} . '@' . $record->{Host};
}

sub nick_channels {
	my ($self) = shift;
	my ($nick) = lc( $_[0] ) || return ();
	my (@result);

	unless ( $self->_nick_exists($nick) ) {
		return @result;
	}

	foreach
	  my $channel ( keys %{ $_[SENDER]->{state}->{Nicks}->{$nick}->{CHANS} } )
	{
		print "got one: ".$_[SENDER]->{state}->{Chans}->{$channel}->{Name}."\n";
		push( @result, $_[SENDER]->{state}->{Chans}->{$channel}->{Name} );
	}
	return @result;
}

sub channel_list {
	my ($self) = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my (@result);

	unless ( $self->_channel_exists($channel) ) {
		return 0;
	}

	foreach
	  my $nick ( keys %{ $_[SENDER]->{state}->{Chans}->{$channel}->{Nicks} } )
	{
		push( @result, $_[SENDER]->{state}->{Nicks}->{$nick}->{Nick} );
	}

	return @result;
}

sub is_operator {
	my ($self) = shift;
	my ($nick) = lc( $_[0] ) || return 0;

	unless ( $self->_nick_exists($nick) ) {
		return 0;
	}

	if ( $_[SENDER]->{state}->{Nicks}->{$nick}->{IRCop} ) {
		return 1;
	}
	return 0;
}

sub is_channel_mode_set {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($mode)    = ( split //, $_[1] )[0] || return 0;

	$mode =~ s/[^A-Za-z]//g;

	unless ( $self->_channel_exists($channel) or $mode ) {
		return 0;
	}

	if ( defined( $_[SENDER]->{state}->{Chans}->{$channel}->{Mode} )
		and $_[SENDER]->{state}->{Chans}->{$channel}->{Mode} =~ /$mode/ )
	{
		return 1;
	}
	return 0;
}

sub channel_limit {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;

	unless ( $self->_channel_exists($channel) ) {
		return 0;
	}

	if ( $self->is_channel_mode_set( $channel, 'l' )
		and defined( $_[SENDER]->{state}->{Chans}->{$channel}->{ChanLimit} ) )
	{
		return $_[SENDER]->{state}->{Chans}->{$channel}->{ChanLimit};
	}
	return 0;
}

sub channel_key {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;

	unless ( $self->_channel_exists($channel) ) {
		return 0;
	}

	if ( $self->is_channel_mode_set( $channel, 'k' )
		and defined( $_[SENDER]->{state}->{Chans}->{$channel}->{ChanKey} ) )
	{
		return $_[SENDER]->{state}->{Chans}->{$channel}->{ChanKey};
	}
	return 0;
}

sub channel_modes {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;

	unless ( $self->_channel_exists($channel) ) {
		return 0;
	}

	if ( defined( $_[SENDER]->{state}->{Chans}->{$channel}->{Mode} ) ) {
		return $_[SENDER]->{state}->{Chans}->{$channel}->{Mode};
	}
	return 0;
}

sub is_channel_member {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;

	unless ( $self->_channel_exists($channel) and $self->_nick_exists($nick) ) {
		return 0;
	}

	if ( defined( $_[SENDER]->{state}->{Chans}->{$channel}->{Nicks}->{$nick} ) )
	{
		return 1;
	}
	return 0;
}

sub is_channel_operator {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;

	unless ( $self->_nick_has_channel_mode( $channel, $nick, 'o' ) ) {
		return 0;
	}
	return 1;
}

sub has_channel_voice {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;

	unless ( $self->_nick_has_channel_mode( $channel, $nick, 'v' ) ) {
		return 0;
	}
	return 1;
}

sub is_channel_halfop {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;

	unless ( $self->_nick_has_channel_mode( $channel, $nick, 'h' ) ) {
		return 0;
	}
	return 1;
}

sub is_channel_owner {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;

	unless ( $self->_nick_has_channel_mode( $channel, $nick, 'q' ) ) {
		return 0;
	}
	return 1;
}

sub is_channel_admin {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($nick)    = lc( $_[1] ) || return 0;

	unless ( $self->_nick_has_channel_mode( $channel, $nick, 'a' ) ) {
		return 0;
	}
	return 1;
}

sub ban_mask {
	my ($self)    = shift;
	my ($channel) = lc( $_[0] ) || return 0;
	my ($mask)    = parse_ban_mask( $_[1] ) || return 0;
	my (@result);

	unless ( $self->_channel_exists($channel) ) {
		return @result;
	}

	# Convert the mask from IRC to regex.
	$mask = lc($mask);
	$mask = quotemeta $mask;
	$mask =~ s/\\\*/[\x01-\xFF]{0,}/g;
	$mask =~ s/\\\?/[\x01-\xFF]{1,1}/g;

	foreach my $nick ( $self->channel_list($channel) ) {
		if ( lc( $self->nick_long_form($nick) ) =~ /^$mask$/ ) {
			push( @result, $nick );
		}
	}

	return @result;
}

1;
