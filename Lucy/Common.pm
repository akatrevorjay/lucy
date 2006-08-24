#!/usr/bin/perl
# SVN: $Id: Common.pm 206 2006-05-19 03:51:55Z trevorj $
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
	my ( $name, $desc, $level ) = @_;
	my $color;
	if ( $level <= 4 ) {
		$color = 'bold';
	}
	if ( $Lucy::config->{debug_level} >= $level ) {
		$name = pack( "A8", $name );
		print colored( time, 'white' )
		  . " $level|"
		  . colored( $name, $color )
		  . "| $desc\n";
	}
}

sub parseumask {
	my ($who) = @_;
	if ( my ( $nick, $username, $host ) = split( /[@!]/, $who, 3 ) ) {
		return {
			nick     => $nick,
			username => $username,
			host     => $host
		};
	} else {
		return undef;
	}
}

sub parsenick {
	my ($nick) = @_;
	if ( $nick =~ /^([\&\@\+\%\~]?)(.*)$/ ) {
		return {
			status => $1,
			nick   => $2
		};
	} else {
		return undef;
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
	} else {
		return undef;
	}
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
		my $header;
		my $footer;
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
m~(?:http://(?:(?:(?:(?:(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?))|(?:(?:\d+)(?:\.(?:\d+)){3}))(?::(?:\d+))?)(?:\/(?:(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*)(?:/(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*))*)(?:\?(?:(?:(?:[a-zA-Z\d\$\-_.+!*'(),]|(?:%[a-fA-F\d]{2}))|[;:@&=])*))?)?)~o
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

#####
## Generic cache object
##
##
# Options ##################################################################
#
# Debug =>      0 - DEFAULT, no debugging output
#               1 - prints cache statistics upon destroying
#               2 - prints detailed debugging info
#
# MaxCount =>   Maximum entries in cache.
#
# MaxBytes =>   Maximum bytes taken in memory for cache based on approximate
#               size of total cache structure in memory
#
#               There is approximately 240 bytes used per key/value pair in the cache for
#               the cache data structures, so a cache of 5000 entries would take
#               at approximately 1.2M plus the size of the data being cached.
#
# MaxSize  =>   Maximum size of each cache entry. Larger entries are not cached.
#                   This helps prevent much of the cache being flushed when
#                   you set an exceptionally large entry.  Defaults to MaxBytes/10
#
# WriteSync =>  1 - DEFAULT, write() when data is dirtied for
#                   TRUE CACHE (see below)
#               0 - write() dirty data as late as possible, when leaving
#                   cache, or when cache is being DESTROY'd
#
############################################################################
#package Lucy::CacheLRU;
#use warnings;
#use strict;
#use vars qw(@ISA);
#@ISA = qw(Tie::Cache);
#
#sub read {
#	my ( $self, $key ) = @_;
#	print "cache miss for $key, read() data\n";
#	undef;
#}
#
#sub write {
#	my ( $self, $key, $value ) = @_;
#	print "flushing [$key, $value] from cache, write() data\n";
#}
#
#1;

######
### Generic ancessor object.
### Could come in handy ;) especially to subclass.
###
##TODO make this capable of being an LRU cache
#package Lucy::GenericObject;
#use strict;
#use Carp;
#use vars qw($AUTOLOAD);
#
#sub AUTOLOAD {
#	my $self = shift;
#	my $attr = $AUTOLOAD;
#	$attr =~ s/.*:://;
#	return unless $attr =~ /[^A-Z]/;    # skip DESTROY and all-cap methods
#	return 1 if ( $attr =~ /_init|_put|_get|_delete/ );
#
#	# Are there any args? if so, put.
#	if (@_) {
#		$self->put( $attr, @_ );
#	}
#	return $self->get($attr);
#}
#
## get rid of it
#sub delete {
#	my ( $self, $attr ) = @_;
#
#	# Convert to uppercase if case insensitive?
#	$attr = uc $attr if defined $self->{case_insensitive};
#
#	#TODO should this only delete the key if the _delete function returns ok?
#	if ( $self->_delete($attr) ) {
#		delete $self->{$attr};
#		return 1;
#	}
#	return undef;
#}
#
## we're saving something.
#sub put {
#	my ( $self, $attr ) = @_;
#
#	# Convert to uppercase if case insensitive
#	$attr = uc $attr if defined $self->{case_insensitive};
#
#	# do we have a defined set of fields?
#	if ( defined $self->{fields} ) {
#		return undef unless defined $self->{fields}{$attr};
#	}
#
#	if ( my $data = shift ) {
#
#		#TODO should this only put the data if the _put function returns ok?
#		if ( $self->_put( $attr, $data ) ) {
#			$self->{data}{$attr} = $data;
#			return 1;
#		}
#	} else {
#		return $self->delete($attr);
#	}
#
#	return undef;
#}
#
## get it damnit.
#sub get {
#	my ( $self, $attr ) = @_;
#
#	# Convert to uppercase if case insensitive
#	$attr = uc $attr if defined $self->{case_insensitive};
#
#	$self->{data}{$attr} = $self->_get($attr)
#	  unless defined $self->{data}{$attr};
#	return $self->{data}{$attr} || undef;
#}
#
#sub new {
#	my $class = shift;
#
#	#my $class = ref($proto) || $proto;
#	#my $parent = ref($proto) && $proto;
#
#	my %params;
#	if ( @_ % 2 ) {
#		%params = @_;
#
#		# Convert to uppercase if case insensitive
#		if ( $params{case_insensitive} ) {
#			foreach ( keys %{ $params{data} } ) {
#				next if uc($_) eq $_;
#				$params{data}{ uc $_ } = $params{data}{$_};
#				delete $params{data}{$_};
#			}
#		}
#	}
#	my $self = bless \%params, $class;
#	undef %params;
#	$self->_init;
#	return $self;
#}
#
#1;
