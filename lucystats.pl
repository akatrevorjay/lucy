#!/usr/bin/perl
# SVN: $Id: lucystats.pl 194 2006-05-11 20:44:45Z trevorj $
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
# These alter the paths for perl to look for Lucy::Config and Lucy libs.
BEGIN {
	my $lucy_path = "/home/trevorj/code/perl/lucy";
	unshift( @INC, $lucy_path . '/lib' );
	unshift( @INC, $lucy_path );
}
use CGI qw(:standard);
use Lucy::Config;
use Cache::FileCache;
use warnings;
use strict;
use vars qw($VERSION);
$VERSION = "0.41";

#use Data::Dumper;

# grab cache object
my $cache =
  new Cache::FileCache(
	{ 'namespace' => 'LucyStats', 'default_expires_in' => 600 } );

my $type =
  ( param('type') && param('type') =~ /^(?:xml|php)$/ ) ? param('type') : 'xml';

#$cache->clear();
unless ( $cache->get( 'lucystats-' . $VERSION . "-timestamp" ) ) {

	# stats are more than 10 minutes old, regenerate.
	my $stats = updatestats();

	# save new stats to cache
	if ($stats) {
		$cache->set( 'lucystats-' . $VERSION . '-xml',
			updatestats_xml($stats) );
		$cache->set( 'lucystats-' . $VERSION . '-php',
			updatestats_php($stats) );
		$cache->set( 'lucystats-' . $VERSION . '-timestamp', time );
	}

	undef $stats;
}

if ( $type eq 'php' ) {
	print header('text/plain'), $cache->get( 'lucystats-' . $VERSION . '-php' );
} elsif ( $type eq 'xml' ) {
	print header('text/xml'), $cache->get( 'lucystats-' . $VERSION . '-xml' );
}

exit;

###
### Update the stats file for dynamicness
###
sub updatestats {
	use DBIx::Simple;

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
		$donuts->{channel}[$i]{topic}       = $q->{topic};
		$donuts->{channel}[$i]{topicauthor} = $q->{topicauthor};
		$donuts->{channel}[$i]{kickcount}   = $q->{kickcount};
		$donuts->{channel}[$i]{name}        = $channel;
		undef $q;

		#TODO chan.topictime - modes: aqv
		$donuts->{channel}[$i]{user} = $dbh->query(
"SELECT nick, connecttime, away, country, seen, ts, lucy_users.mode_lo
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

sub updatestats_php {
	my $mmm = shift;
	use serialize;

	return serialize($mmm);
}

sub updatestats_xml {
	my $mmm = shift;
	use XML::Smart;

	#print Data::Dumper->Dump([$mmm], [qw(stats)]);

	my $XML   = XML::Smart->new();
	my $stats = $XML->{lucystats};
	$stats->set_auto(0);

	### Save timestamp
	$stats->{ts} = $mmm->{ts};
	$stats->{ts}->set_node(1);
	foreach ( keys %$mmm ) {
		$stats->{$_} = $mmm->{$_};
	}

	return q`<?xml version="1.0" encoding="utf-8" ?>
<?xml-stylesheet type="text/xsl" href="lucystats.xsl"?>
` . $XML->data( noheader => 1, nometagen => 1 );
}
