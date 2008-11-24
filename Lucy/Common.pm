#!/usr/bin/perl
# SVN: $Id$
# Common functions
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
package Lucy::Common;
use Term::ANSIColor;
use Time::Interval;
use Crypt::Random;
use warnings;
use strict;
use Switch;
use vars qw(@ISA @EXPORT);
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(parseumask parsenick debug timesince ison trim font crand);

# this uses crypt::random for more random values
sub crand {
	my $upper = shift;
	my $lower = shift || 0;

	# We can't use zero as a lower, so, bump.
	$lower++;
	$upper++;

	return (
		Crypt::Random::makerandom_itv(
			Strength => 1,
			Lower    => $lower,
			Upper    => $upper
		  ) - 1
	);
}

sub debug {
	return undef unless $Lucy::config->{debug_level} >= $_[2];

	my ( $name, $desc, $level ) = @_;
	$name = pack( "A12", $name );

	my $time = colored(time, 'white');
	
	if ($level <= 1) {
		$name = colored($name, 'bold white on_red');
		$desc = colored($desc, 'bold white on_red');
	} elsif ($level <= 2) {
		$name = colored($name, 'bold blue on_black');
	} elsif ($level <= 4) {
		$name = colored($name, 'bold green on_black');
	} elsif ($level <= 6) {
		$name = colored($name, 'bold');
	}

	print "$time $level|$name| $desc\n"
}

sub parseumask {
	my ($who) = @_;

	if ( my ( $full_nick, $username, $host ) = split( /[@!]/, $who, 3 ) ) {
		my ($nick_status, $nick) = parsenick($full_nick);
		$nick = $full_nick unless defined $nick;

		my %ret;
		foreach ([qw(full_nick nick nick_status username host)]) {
			$ret{$_} = eval("return \$$_ or undef");
		}
		return %ret;
	}
}

sub parsenick {
	my ($nick) = @_;

	if ( $nick =~ /^([\&\@\+\%\~]?)(.*)$/ ) {
		return wantarray ? { nick => $2, status => $1 } : $2;
	}
}

sub timesince {
	my $ts  = shift;
	my $pit = parseInterval(
		seconds => ( time() - $ts ),
		string  => 1,
	);

	my $timesince;
	foreach (qw/days hours minutes seconds/) {
		if ( $pit->{$_} ) {
			$timesince .= $pit->{$_} . substr( $_, 0, 1 ) . ',';
		}
	}
	undef $pit;
	$timesince = substr( $timesince, 0, -1 ) if ($timesince);
	return $timesince || undef;
}

sub ison {
	my ( $self, $nick ) = @_;

	if (
		my $ref = $Lucy::dbh->query(
"SELECT COUNT(*) FROM ison, user WHERE ison.nickid = user.nickid AND user.nick = ?",
			$nick
		)->array
	  )
	{
		return $ref->[0];
	}
	undef;
}

# trims $what to a certain length
sub trim {
	my $what   = shift || return undef;
	my $length = shift || 30;

	if ( length($what) > $length ) {
		$what = substr( $what, 0, $length ) . '...';
	}
	return $what;
}

sub font {
	my ( $attribs, $text ) = @_;

	if ( $Lucy::config->{UseIRCColors} ) {
		my ( $header, $footer );
		foreach my $attrib ( split( / /, $attribs ) ) {
			switch ($attrib) {
				case 'black' {
					$header .= "\3" . "1";
					$footer .= "\3";
				}
				case 'darkblue' {
					$header .= "\3" . "2";
					$footer .= "\3";
				}
				case 'darkgreen' {
					$header .= "\3" . "3";
					$footer .= "\3";
				}
				case 'red' {
					$header .= "\3" . "4";
					$footer .= "\3";
				}
				case 'darkred' {
					$header .= "\3" . "5";
					$footer .= "\3";
				}
				case 'darkpurple' {
					$header .= "\3" . "6";
					$footer .= "\3";
				}
				case /brown|orange/ {
					$header .= "\3" . "7";
					$footer .= "\3";
				}
				case 'yellow' {
					$header .= "\3" . "8";
					$footer .= "\3";
				}
				case 'green' {
					$header .= "\3" . "9";
					$footer .= "\3";
				}
				case 'teal' {
					$header .= "\3" . "10";
					$footer .= "\3";
				}
				case 'lightblue' {
					$header .= "\3" . "11";
					$footer .= "\3";
				}
				case 'blue' {
					$header .= "\3" . "12";
					$footer .= "\3";
				}
				case 'purple' {
					$header .= "\3" . "13";
					$footer .= "\3";
				}
				case /darkgr[ae]y/ {
					$header .= "\3" . "14";
					$footer .= "\3";
				}
				case /^gr[ae]y/ {
					$header .= "\3" . "15";
					$footer .= "\3";
				}
				case 'white' {
					$header .= "\3" . "16";
					$footer .= "\3";
				}
				case 'bold' {
					$header .= "\2";
					$footer .= "\2";
				}
				case /^inver/ {
					$header .= "\26";
					$footer .= "\26";
				}
				case 'underline' {
					$header .= chr(31);
					$footer .= chr(31);
				}
			}
		}
		return $header . $text . $footer;
	} else {
		return $text;
	}
}

sub isurl {
	if ( $_[0] =~
m~(?:https?://(?:(?:(?:(?:(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?))|(?:(?:\d+)(?:\.(?:\d+)){3}))(?::(?:\d+))?)(?:\/(?:(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*)(?:/(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*))*)(?:\?(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*))?)?)~o
	  )
	{
		return 1;
	}
	undef;
}

# checks if $hostname is a valid hostname or ip
sub ishostname {
	if ( $_[0] =~
/(?:(?:(?:(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?))|(?:(?:\d+)(?:\.(?:\d+)){3}))/o
	  )
	{
		return 1;
	}
	undef;
}

1;
