#!/usr/bin/perl
# SVN: $Id: ChuckNorris.pm 202 2006-05-16 06:41:49Z trevorj $
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
use POE;
use XML::Smart;
use Acme::Magic8Ball qw(ask);
use Acme::Scurvy::Whoreson::BilgeRat;
use Math::Expression;
use warnings;
use strict;

#### The acronyms of defeat shall pwn thee
#sub irc_public {
#	my ( $self, $lucy, $who, $where, $what ) =
#	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
#	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
#	$where = $where->[0];
#
##-- Apparently, linolium doesn't like funny, spunky, and random injections into the conversation... =(
##	# Make lucy spit out random messages at times of boredom
##	# maybe we could increase the odds if nobody has talked for a while?
##	if ( Lucy::crand(50) + 1300 == 1337 ) {
##		my @r = (
##			'Hows Chuck Norris doing?',
##			'Lets talk about sex and stargates',
##			'someone pinch me, I think my ear is bleeding'
##		);
##		$lucy->privmsg( $where, $r[ Lucy::crand($#r+1) ] );
##	}
#
#	return 0;
#}

### I'm Spider Man, Bitch.
sub irc_bot_command {
	my ( $self, $kernel, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, KERNEL, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	# Russian roulette
	if ( $cmd eq 'load' ) {
		if ( defined $self->{gunchamber} ) {
			$lucy->yield( kill => $nick =>
				  "BANG - Don't stuff bullets into a loaded gun" );
		} else {
			$self->{gunchamber} = 1 + Lucy::crand(6);
			$lucy->yield( ctcp => $where => 'ACTION' =>
				  'loads the gun and sets it on the table' );
		}
	} elsif ( $cmd eq 'shoot' ) {
		if (   ( !defined $self->{gunchamber} )
			|| ( $self->{gunchamber} <= 0 ) )
		{
			$lucy->yield( privmsg => $where =>
"$nick: You probrably want to !load the gun first, don't you think?"
			);
		} else {
			$self->{gunchamber}--;
			if ( $self->{gunchamber} == 0 ) {
				$lucy->yield( privmsg => $nick => "Bang!!!" );
				$lucy->yield(
					privmsg => $nick => "Better luck next time, $nick" );
				$lucy->yield( kill => $nick => "BANG!!!!" );
				delete $self->{gunchamber};
			} else {
				$lucy->yield( privmsg => $nick => "click" );
			}
		}

		# Insult
	} elsif ( ( $cmd eq 'insult' )
		&& ( my ( $iwho, $itype ) = $args =~ /^(.*?)\s*(?:like an? (\w+))?$/i )
	  )
	{

		#TODO check if it's in the array, don't hardcode it twice
		my @langs = ( 'insultserver', 'pirate' );
		$itype = $langs[ int rand( $#langs + 1 ) ]
		  unless ( $itype =~ /(?:insultserver|pirate)/ );
		$iwho = $nick unless ($iwho);

		my $insult =
		  Acme::Scurvy::Whoreson::BilgeRat->new( language => $itype );
		$lucy->yield( privmsg => $where => "$iwho: $insult" );
		undef $insult;

		# Run math expressions
	} elsif ( $cmd eq 'math' ) {
		unless ( $args eq 'help' ) {

# Idea borrowed from Bot::BasicBot ;)
# The author of it, Simon Wistow, is a great man with some great code. Check him out on CPAN!
			my $calc = Math::Expression->new;
			$calc->SetOpt( PrintErrFunc => sub { } );

			# should this need to be in an eval?
			my $answer = $calc->EvalToScalar( $calc->Parse($args) )
			  || undef;
			undef $calc;
			if ($answer) {
				$lucy->yield( privmsg => $where => "$nick: $answer" );
			} else {
				$lucy->yield(
					privmsg => $where => "$nick: expression failed bitch" );
			}
		} else {
			$lucy->yield( privmsg => $where =>
"$nick: syntax is available at http://search.cpan.org/~addw/Math-Expression-1.14/Expression.pm"
			);
		}

		# Current US terror level
	} elsif ( $cmd eq 'terror' ) {
		### trevorj: I edited this to do it manually, because theres no point in loading
		### XML::Simple (required by Acme::Terror) if we use XML::Smart in other plugins
		if (
			my $XML = XML::Smart->new(
				"http://www.dhs.gov/dhspublic/getAdvisoryCondition"
			)
		  )
		{
			$XML = $XML->cut_root;
			$lucy->yield(
				privmsg => $where => "WHOA!! TAKE COVER!!! TERROR LEVEL IS "
				  . $XML->{CONDITION} );
			undef $XML;
		}

		# Magic Eight Ball
	} elsif ( $cmd eq '8ball' ) {
		$lucy->privmsg( $where, "$nick: " . ask($args) );

		# Rot13 unbreakable encryption
	} elsif ( $cmd eq 'rot13' ) {
		$args =~ tr[a-zA-Z][n-za-mN-ZA-M];
		$lucy->yield( privmsg => $where => $args );

		# change the debug level
	} elsif ( $cmd eq 'debug' ) {
		if ( $args =~ /(?:level=)?([4-8])/ ) {
			Lucy::debug( "debug", "--- SET DEBUG LEVEL TO $1 ---", 2 );
			$Lucy::config->{debug_level} = scalar($1);
		}

		# Turn colors on/off
	} elsif ( ( $cmd eq 'colors' )
		&& ( $args =~ /^(?:on|off)$/i ) )
	{
		$Lucy::config->{UseIRCColors} = ( $args eq 'on' ) ? 1 : 0;
	}

#TODO some kind of auth system is required for such powerful functions
#FUCK diamond_add doesn't work correctly. remove|reload work fine.
#elsif ($cmd eq 'dadd') {
#	if ($args =~ /\w{3,20}/) {
#		Lucy::debug( "Connect", "Loading diamond $args by $nick\'s request..", 1 );
#		$lucy->add_diamond, $args);
#	}
#}
#elsif ($cmd eq 'dremove') {
#	if ($args =~ /\w{3,20}/) {
#		Lucy::debug( "Connect", "Unloading diamond $args by $nick\'s request..", 1 );
#		$lucy->remove_diamond, $args);
#	}
#}
	elsif ( $cmd eq 'reload' ) {
		if ( $args =~ /\w{3,20}/ ) {
			Lucy::debug( "ChuckNorris",
				"Reloading diamond $args by $nick\'s request...", 1 );
			if ( $lucy->reload_diamond($args) ) {
				$lucy->yield( privmsg => $where => "$nick: ok" );
			} else {
				$lucy->yield(
					privmsg => $where => "$nick: failed to reload $args" );
			}
		}

		#} elsif ( $cmd eq 'lag' ) {
		#	TODO doesn't work =/
		#	$lucy->privmsg( $where, "$nick: lag is " . $lucy->lag() );
	} else {

		return 0;
	}
}

### Mmmm. We have been loaded.
sub new {
	return bless {}, shift;
}

1;
