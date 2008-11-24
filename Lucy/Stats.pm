#!/usr/bin/perl
# SVN: $Id$
# This is meant as a replacement for the Stats plugin. It's meant for your cgi-bin.
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
package Lucy::Stats;
use Lucy::Config;
use DBIx::Simple;
use warnings;
use strict;

sub new {
	my $class = shift;
	return bless {}, $class;
}

# fetch stats data into a raw hash
sub fetch {
	my $self        = shift;
	my $filter_name = shift || 'xml';

	# sanitize the filter name for badness
	unless ( $filter_name =~ /^[\w_-]+$/ ) {
		warn "WTF. $filter_name has bad characters in it.\n";
		return;
	}

	# easy-access zipper
	my $filter = "Lucy::Stats::$filter_name";

	# can we load the filter?
	#always returns false.
	eval("use $filter");

	# can we make a new instance of it?
	my $f = eval("return $filter->new();");
	unless ($f) {
		warn "WTF. Could not run $filter\n";
		return;
	}

	# can we runTheSilkScreen?
	unless ( eval { $f->can('runTheSilkScreen') } ) {
		warn 'WTF. Lucy::Stats::' . $filter
		  . '->can("runTheSilkScreen") returned false!';
		return;
	}

# This is so you can run fetch() more than once without grabbing the stats again.
	unless ( exists( $self->{donuts_ts} ) && $self->{donuts_ts} + 10 > time ) {
		$self->{donuts}    = $self->fetch_raw();
		$self->{donuts_ts} = time;
	}
	my $frosting = $f->runTheSilkScreen( $self->{donuts} );
	return $frosting;
}

sub clear_table {
	my $self = shift;
	delete( $self->{donuts} );
	delete( $self->{donuts_ts} );
}

sub fetch_raw {
	my $self   = shift;
	my $donuts = {};

	# grab dbi object
	my $dbh = DBIx::Simple->connect(
		$config->{DBdsn},
		$config->{DBuser},
		$config->{DBpass},
		{
			RaiseError => 0,
			AutoCommit => 1,
			PrintWarn  => ( $config->{debug_level} > 6 ) ? 1 : 0,
			PrintError => ( $config->{debug_level} > 4 ) ? 1 : 0
		}
	);

	$donuts->{ts} = time;

	@{ $donuts->{link} } = $dbh->select(
		'server',
		[
			qw(servid server hops comment linkedto connecttime online lastsplit uptime currentusers)
		]
	)->hashes;

	my $i = 0;
	foreach my $channel ( keys %{ $config->{Channels} } ) {

		# don't show the stats for the ops channel ;)
		next if ( $channel eq '#neoturbine-ops' );

		my $q = $dbh->query(
"SELECT topic, topicauthor, kickcount FROM chan WHERE chan.channel = ?",
			$channel
		)->hash;
		$donuts->{channel}[$i] = \%$q;

		#		$donuts->{channel}[$i]{topic}       = $q->{topic};
		#		$donuts->{channel}[$i]{topicauthor} = $q->{topicauthor};
		#		$donuts->{channel}[$i]{kickcount}   = $q->{kickcount};
		$donuts->{channel}[$i]{name} = $channel;
		undef $q;

		#TODO chan.topictime - modes: aqv
		$donuts->{channel}[$i]{user} = $dbh->query(
"SELECT nick, connecttime, away, country, seen, ts, lucy_users.mode_lo, lucy_users.mode_la, lucy_users.mode_lq, lucy_users.mode_lv
FROM lucy_users, chan, ison
WHERE chan.channel = ? AND lucy_users.nickid = ison.nickid AND chan.chanid = ison.chanid
ORDER BY ts DESC LIMIT 20", $channel
		)->hashes;

		$i++;
	}
	undef $i;

# This is just selecting three random rows more efficiently since the factoids table can get big.
	@{ $donuts->{factoid} } = $dbh->query(
		"SELECT fact,definition,who FROM lucy_factoids AS r1 JOIN
			(SELECT ROUND(RAND() * (SELECT MAX(id) FROM lucy_factoids)) AS id) AS r2
			WHERE r1.id >= r2.id ORDER BY r1.id ASC LIMIT 3"
	)->hashes;

	undef $dbh;
	return $donuts;
}

1;
