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
package Lucy::Diamonds::ChuckNorris;
use base qw(Lucy::Diamond);
use warnings;
use strict;

sub commands {
	return {
		russianroulette_load  => [qw(load)],
		russianroulette_shoot => [qw(shoot bang)],
		eightball             => [qw(ask eightball 8ball)],
		insult                => [qw(insult)],
		math                  => [qw(math calc)],
		rot13                 => [qw(rot13 xor)],
		terror_level          => [qw(terror)],

		diamond_load   => [qw(diamond_load dload dadd)],
		diamond_unload => [qw(diamond_unload dunload ddel)],
		diamond_reload => [qw(diamond_reload dreload drel reload)],
		timesince      => [qw(timesince)],
		use_irc_colors => [qw(colors)],
		debug_level    => [qw(debug)],
	};
}

##
## Russian roulette
##

sub russianroulette_load {
	my ( $self, $v ) = @_;

	if ( defined $self->{gunchamber} ) {
		$Lucy::lucy::lucy->yield( kill => $v->{nick} =>
			  "BANG - Don't stuff bullets into a loaded gun" );
	} else {
		$self->{gunchamber} = 1 + Lucy::crand(6);
		$Lucy::lucy::lucy->yield( ctcp => $v->{where} => 'ACTION' =>
			  'loads the gun and sets it on the table' );
	}
}

sub russianroulette_shoot {
	my ( $self, $v ) = @_;
	my @msg;

	if (   ( !defined $self->{gunchamber} )
		|| ( $self->{gunchamber} <= 0 ) )
	{
		push( @msg,
			"You probrably want to !load the gun first, don't you think?" );
		return @msg;
	} else {
		$self->{gunchamber}--;
		if ( $self->{gunchamber} == 0 ) {
			$Lucy::lucy::lucy->yield( privmsg => $v->{nick} => "Bang!!!" );
			$Lucy::lucy::lucy->yield(
				privmsg => $v->{nick} => "Better luck next time, $v->{nick}" );
			$Lucy::lucy::lucy->yield( kill => $v->{nick} => "BANG!!!!" );
			delete $self->{gunchamber};
		} else {
			$Lucy::lucy::lucy->yield( privmsg => $v->{nick} => "click" );
		}
	}
}

## insultserver mimick
use Acme::Scurvy::Whoreson::BilgeRat;

sub insult {
	my ( $self, $v ) = @_;

	if ( my ( $iwho, $itype ) = $v->{args} =~ /^(.*?)\s*(?:like an? (\w+))?$/i )
	{
		my %langs = ( insultserver => 1, pirate => 1, lala => 1 );

		unless ( exists $langs{$itype} ) {
			my @langtypes = keys %langs;
			$itype = $langtypes[ int rand( $#langtypes + 1 ) ];
		}
		$iwho = $v->{nick} unless ($iwho);

		my $insult =
		  Acme::Scurvy::Whoreson::BilgeRat->new( language => $itype );
		$Lucy::lucy->yield( privmsg => $v->{where} => "$iwho: $insult" );
		undef $insult;
	}
}

# Run math expressions
use Math::Expression;

sub math {
	my ( $self, $v ) = @_;

	if ( $v->{args} eq 'help' ) {
		$Lucy::lucy->yield( privmsg => $v->{where} =>
"$v->{nick}: syntax is available at http://search.cpan.org/~addw/Math-Expression-1.14/Expression.pm"
		);
	}

# Idea borrowed from Bot::BasicBot ;)
# The author of it, Simon Wistow, is a great man with some great code. Check him out on CPAN!
	my $calc = Math::Expression->new;
	$calc->SetOpt( PrintErrFunc => sub { } );

	my $answer = $calc->EvalToScalar( $calc->Parse( $v->{args} ) )
	  || undef;
	undef $calc;
	if ($answer) {
		$Lucy::lucy->yield( privmsg => $v->{where} => "$v->{nick}: $answer" );
	} else {
		$Lucy::lucy->yield(
			privmsg => $v->{where} => "$v->{nick}: expression failed bitch" );
	}
}

# Current US terror level
use XML::Smart;

sub terror_level {
	my ( $self, $v ) = @_;

	if ( my $XML =
		XML::Smart->new("http://www.dhs.gov/dhspublic/getAdvisoryCondition") )
	{
		$XML = $XML->cut_root;
		$Lucy::lucy::lucy->yield(
			privmsg => $v->{where} => "WHOA!! TAKE COVER!!! TERROR LEVEL IS "
			  . $XML->{CONDITION} );
		undef $XML;
	}
	return 1;
}

# Magic Eight Ball
use Acme::Magic8Ball qw(ask);

sub eightball {
	my ( $self, $v ) = @_;
	$Lucy::lucy->privmsg( $v->{where}, "$v->{nick}: " . ask( $v->{args} ) );
}

# Rot13 unbreakable encryption
sub rot13 {
	my ( $self, $v ) = @_;
	$v->{args} =~ tr[a-zA-Z][n-za-mN-ZA-M];
	$Lucy::lucy->yield( privmsg => $v->{where} => $v->{args} );
}

# change the debug level
sub debug_level {
	my ( $self, $v ) = @_;
	if ( $v->{args} =~ /(?:level=)?([4-8])/ ) {
		Lucy::debug( "debug", "--- SET DEBUG LEVEL TO $1 ---", 2 );
		$Lucy::lucy::config->{debug_level} = scalar($1);
	}
}

# Turn colors on/off
sub use_irc_colors {
	my ( $self, $v ) = @_;
	if ( $v->{args} =~ /^(?:on|off)$/i ) {
		$Lucy::lucy::config->{UseIRCColors} = ( $v->{args} eq 'on' ) ? 1 : 0;
	}
}

##
## Diamond-related functions
##
#TODO some kind of auth system is required for such powerful functions
#FUCK diamond_load doesn't work correctly. remove|reload work fine.
sub diamond_load {
	my ( $self, $v ) = @_;

	if (   $v->{type} eq 'pub'
		&& $Lucy::lucy->is_channel_admin( $v->{where}, $v->{nick} )
		&& $v->{args} =~ /\w{3,20}/ )
	{
		Lucy::debug( "ChuckNorris",
			"Loading diamond $v->{args} by $v->{nick}\'s request..", 1 );
		$Lucy::lucy->add_diamond( $v->{args} );
	}
}

sub diamond_unload {
	my ( $self, $v ) = @_;

	if (   $v->{type} eq 'pub'
		&& $Lucy::lucy->is_channel_admin( $v->{where}, $v->{nick} )
		&& $v->{args} =~ /\w{3,20}/ )
	{
		Lucy::debug( "ChuckNorris",
			"Unloading diamond $v->{args} by $v->{nick}\'s request..", 1 );
		$Lucy::lucy->remove_diamond( $v->{args} );
	}
}

sub diamond_reload {
	my ( $self, $v ) = @_;

	if (   $v->{type} eq 'pub'
		&& $Lucy::lucy->is_channel_admin( $v->{where}, $v->{nick} ) )
	{
		Lucy::debug(
			"ChuckNorris",
			"Reloading diamonds that have changed by $v->{nick}\'s request...",
			1
		);
		if ( $Lucy::lucy->reload_diamond() ) {
			$Lucy::lucy->yield( privmsg => $v->{where} => "$v->{nick}: ok" );
		} else {
			$Lucy::lucy->yield(
				privmsg => $v->{where} => "$v->{nick}: failed to reload" );
		}
	}
}

## DANANANAnanananaNA timesince!
sub timesince {
	my ( $self, $v ) = @_;

	if ( $v->{args} =~ /^\d+$/ ) {
		$Lucy::lucy->yield(
			    privmsg => $v->{where} => "$v->{nick}: $v->{args} was "
			  . Lucy::timesince( $v->{args} )
			  . ' ago.' );
	}
}

#### The acronyms of defeat shall pwn thee
#sub irc_public {
#	my ( $self, $Lucy::lucy, $who, $v->{where}, $what ) =
#	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
#	my $v->{nick} = ( split( /[@!]/, $who, 2 ) )[0];
#	$v->{where} = $v->{where}->[0];
#
##-- Apparently, linolium doesn't like funny, spunky, and random injections into the conversation... =(
##	# Make lucy spit out random messages at times of boredom
##	# maybe we could increase the odds if nobody has talked for a while?
##	if ( Lucy::crand(50) + 1300 == 1337 ) {
##		my @r = (
##			'Hows Chuck Norris doing?',
##			'Lets talk about sex and stargates',
##			'How about sex WITH a stargate??!? o_O',
##			'someone pinch me, I think my ear is bleeding'
##		);
##		$Lucy::lucy->privmsg( $v->{where}, $r[ Lucy::crand($#r+1) ] );
##	}
#
#	return 0;
#}

1;
