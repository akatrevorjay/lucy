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

		diamond_list   => [qw(diamond_list dlist)],
		diamond_add    => [qw(diamond_load diamond_add dload dadd)],
		diamond_remove => [qw(diamond_unload diamond_remove dunload dremove)],
		diamond_reload => [qw(diamond_reload dreload reload)],
		command_list   => [qw(command_list commands_list commands)],
		timesince      => [qw(timesince)],

		#		use_irc_colors => [qw(colors)],
		debug_level => [qw(debug)],
		version     => [qw(version)],
	};
}

##
## Russian roulette
##

sub russianroulette_load {
	my ( $self, $v ) = @_;

	if ( defined $self->{gunchamber} ) {
		$Lucy::lucy->yield( kill => $v->{nick} =>
							"BANG - Don't stuff bullets into a loaded gun" );
	} else {
		$self->{gunchamber} = 1 + Lucy::crand(6);
		$Lucy::lucy->yield( ctcp => $v->{where} => 'ACTION' =>
							'loads the gun and sets it on the table' );
	}
}

sub russianroulette_shoot {
	my ( $self, $v ) = @_;
	my @msg;

	if (    ( !defined $self->{gunchamber} )
		 || ( $self->{gunchamber} <= 0 ) )
	{
		push( @msg,
			  "You probrably want to !load the gun first, don't you think?" );
		return @msg;
	} else {
		$self->{gunchamber}--;
		if ( $self->{gunchamber} == 0 ) {
			$Lucy::lucy->yield( privmsg => $v->{nick} => "Bang!!!" );
			$Lucy::lucy->yield(
				 privmsg => $v->{nick} => "Better luck next time, $v->{nick}" );
			$Lucy::lucy->yield( kill => $v->{nick} => "BANG!!!!" );
			delete $self->{gunchamber};
		} else {
			$Lucy::lucy->yield( privmsg => $v->{nick} => "click" );
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
		$Lucy::lucy->yield(
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
	return 1;
}

# Rot13 unbreakable encryption
sub rot13 {
	my ( $self, $v ) = @_;
	$v->{args} =~ tr[a-zA-Z][n-za-mN-ZA-M];
	$Lucy::lucy->yield( privmsg => $v->{where} => $v->{args} );
	return 1;
}

# change the debug level
sub debug_level {
	my ( $self, $v ) = @_;
	if ( $v->{args} =~ /(?:level=)?([4-8])/ ) {
		Lucy::debug( "debug", "--- SET DEBUG LEVEL TO $1 ---", 2 );
		$Lucy::lucy::config->{debug_level} = scalar($1);
		return 1;
	}
}

# Turn colors on/off
sub use_irc_colors {
	my ( $self, $v ) = @_;
	if ( $v->{args} =~ /^(?:on|off)$/i ) {
		$Lucy::lucy::config->{UseIRCColors} = ( $v->{args} eq 'on' ) ? 1 : 0;
		return 1;
	}
}

##
## Diamond-related functions
##
#TODO some kind of auth system is required for such powerful functions
#FUCK diamond_load doesn't work correctly. remove|reload work fine.
sub diamond_add {
	my ( $self, $v ) = @_;

	if (    $v->{type} eq 'pub'
		 && $Lucy::lucy->is_operator( $v->{nick} )
		 && $v->{args} =~ /^\w{0,20}$/ )
	{
		Lucy::debug( "ChuckNorris",
					"Adding diamonds [$v->{args}] by [$v->{nick}]\'s request..",
					1 );
		$Lucy::lucy->add_diamond( $v->{args} );
		return ['ok'];
	}
}

sub diamond_remove {
	my ( $self, $v ) = @_;

	if (    $v->{type} eq 'pub'
		 && $Lucy::lucy->is_operator( $v->{nick} )
		 && $v->{args} =~ /^\w{0,20}$/ )
	{
		Lucy::debug( "ChuckNorris",
				  "Removing diamonds [$v->{args}] by [$v->{nick}]\'s request..",
				  1 );
		$Lucy::lucy->remove_diamond( $v->{args} );
		return ['ok'];
	}
}

sub diamond_reload {
	my ( $self, $v ) = @_;

	if (    $v->{type} eq 'pub'
		 && $Lucy::lucy->is_operator( $v->{nick} )
		 && $v->{args} =~ /^\w{0,20}$/ )
	{
		Lucy::debug( "ChuckNorris",
				"Reloading diamonds [$v->{args}] by [$v->{nick}]\'s request...",
				1 );

		my @diamonds = split( /\s/, $v->{args} );
		$Lucy::lucy->reload_diamond(@diamonds);

		return ['ok'];
	}
}

sub diamond_list {
	my ( $self, $v ) = @_;

	if (    $v->{type} eq 'pub'
		 && $Lucy::lucy->is_operator( $v->{nick} ) )
	{
		Lucy::debug( "ChuckNorris",
					 "Listing diamonds by [$v->{nick}]\'s request", 4 );

		my @diamonds = keys( %{ $Lucy::lucy->{Diamonds} } );
		return ["Loaded Diamonds: @diamonds"];
	}
}

sub commands_list {
	my ( $self, $v ) = @_;
	
	my $msg_str;
	foreach my $d ( keys %{ $Lucy::lucy->{Diamonds} } ) {
		# only work on abstract diamonds for now
		next unless $Lucy::lucy->{Diamonds}{$d}->{__abstract};
		next unless my %commands = %{ $Lucy::lucy->{Diamonds}{$d}->commands };
		
		$msg_str .= "$d=[ ";
		foreach my $c (keys %commands) {
			$msg_str .= "$c";
			$msg_str .= ' aliases=(' . join(',', @$commands{$c} ) . ')'
				if ($v->{args} =~ /aliases/);
			$msg_str .= ",";
		}
		$msg_str .= '], ';
	}

	my @msg = [$msg_str];
	return \@msg;
}

## DANANANAnanananaNA timesince!
sub timesince {
	my ( $self, $v ) = @_;

	if ( $v->{args} =~ /^\d+$/ ) {
		return [
			   $v->{args} . ' was ' . Lucy::timesince( $v->{args} ) . ' ago.' ];
	}
}

sub version {
	my ( $self, $v ) = @_;
	return [ 'Lucy v' . $Lucy::VERSION ];
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
