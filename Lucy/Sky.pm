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
  qw(Component::IRC::State Component::IRC::Plugin::BotTraffic Component::IRC::Plugin::Connector Component::IRC::Plugin::ISupport);
use Lucy::MsgHandler;
use Module::Refresh;
use warnings;
use strict;
no strict 'refs';
use vars qw($AUTOLOAD);

###
### Diamond stuff
###
sub add_diamond {
	my $self = shift;
	foreach my $d (@_) {
		$self->remove_diamond($d) if $self->is_diamond_loaded($d);
		if ( eval( 'return require Lucy::Diamonds::' . $d . ' or undef;' ) ) {
			$self->{Diamonds}{$d} =
			  eval( 'return Lucy::Diamonds::' . $d . '->new() or undef;' );

			# Set the diamond priority
			my $priority =
			  ( exists $self->{Diamonds}{$d}->{priority} )
			  ? $self->{Diamonds}{$d}->{priority}
			  : $self->{default_priority};
			if ( $priority >= 0 ) {
				$self->{Diamonds_map}[$priority]{$d} = 1;
			}

			# On-demand events
			my @methods = $self->{Diamonds}{$d}->methods();
			
			#TODO this doesn't really belong here..
			# We need a way for methods() to see the subs in the Diamond
			# sub-class as well. Then we could avoid this ugliness.
			push( @methods, 'irc_bot_command' )
			  if ( $self->{Diamonds}{$d}{__abstract});

			foreach (@methods) {
				next unless s/^irc_//;
				$self->{Diamonds_events}{$d}{$_} = 1;

  #TODO Does this help with efficiency much at all? Maybe it just eats more ram.
				$self->{Events}{$_} = 1;
			}

			Lucy::debug( "Sky", "Loaded diamond $d [priority=$priority]", 2 );
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
			my $priority =
			  ( exists $self->{Diamonds}{$d}->{priority} )
			  ? $self->{Diamonds}{$d}->{priority}
			  : $self->{default_priority};
			if ( $priority >= 0 ) {
				delete $self->{Diamonds_map}[$priority]{$d};
			}

			delete $self->{Diamonds}{$d};
			delete $self->{Diamonds_events}{$d};
			$self->{refresher}->unload_module( 'Lucy/Diamonds/' . $d . '.pm' );

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
	if (@diamonds) {

		# refresh the diamonds, if modified
		foreach (@diamonds) {
			$self->{refresher}
			  ->refresh_module_if_modified("Lucy/Diamonds/$_.pm");
		}

		# add_diamond will unload the diamond if it's already loaded.
		$self->add_diamond(@diamonds);

   #} else {
   #TODO this is kind of broken, as it doesn't remove and add the diamond again.
   #$self->{refresher}->refresh();
	}
}

sub is_diamond_loaded {
	my ( $self, $diamond ) = @_;
	return ( defined $self->{Diamonds}{$diamond} ) ? 1 : undef;
}

###
### IRC
###
# Some of this was borrowed from PoCo::IRC::Object

sub new {
	my $class = shift;
	die __PACKAGE__ . "->new() params must be a hash" if @_ % 2;
	my %params = @_;

	#FUCK Tunables
	$params{default_priority} = 4;

	my $self = bless \%params, $class;
	$self->init();
	return $self;
}

sub init {
	my ($self) = @_;

	# init module::refresh object
	$self->{refresher} = Module::Refresh->new();

	# Create the component that will represent an IRC network.
	$self->{__irc} =
	  POE::Component::IRC::State->spawn(
		Debug => ( $Lucy::config->{debug_level} > 9 ) ? 1 : 0 );

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

	# since we save the events without irc_, lets get rid of it.
	( my $state_name = $state ) =~ s/^irc_//;

	# run the event on the diamonds, in order of prioritizationing
	if ( $self->{Events}{$state_name} ) {
		foreach my $pri ( 0 .. $#{ $self->{Diamonds_map} } ) {
			next unless defined $self->{Diamonds_map}[$pri];
			Lucy::debug( 'Event' . $pri, "Sending $state", 9 );

			#TODO is this really needed in this foreach as well as the next??
			my $ret;
			foreach my $d ( keys %{ $self->{Diamonds_map}[$pri] } ) {
				next
				  unless ( $self->{Diamonds_events}{$d}{$state_name} );
				$ret = eval { $self->{Diamonds}{$d}->$state(@new_) };

				Lucy::debug(
					'Sky',
					'Compilation of ' . $state . ' @ ' . $d . ' failed: ' . $@,
					0
				) if $@;
				if ($ret) {
					Lucy::debug( 'Event' . $pri,
						$d . ' stopped event of ' . $state, 9 );
					last;
				}
			}
			last if $ret;
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
		) if $@;
	}
	return $ret;
}

1;
