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
	my $lucy_path = "/home/lucy/lucy";
	unshift( @INC, $lucy_path . '/lib' );
	unshift( @INC, $lucy_path );
}
use Lucy::Config;
use DBIx::Simple;
use warnings;
use strict;
use vars qw($VERSION);
$VERSION = "0.1";

sub old_tablename { return 'lucy_factoids' }
sub tablename     { return 'lucy_roids'; }

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
) or die "Cannot connect to DB!";

# Automatically reconnect to the db.
#WTF This is mysql only. Does this fix the reconnect issue with MySQL?
$dbh->{mysql_auto_reconnect} = 1;

my $fact_regex = '[\w\s]{3,32}';
my $trigger_regex = 'is|are|tastes|smells|feels|sounds|says|fucks|rapes|murders|kills|hates|loves';

my $result = $dbh->select(tablename(), [qw/id ts fact definition who/], undef, ['id ASC']);

while (my $r = $result->hash) {
	if (my $dupe = $dbh->select(tablename(), [qw/id ts fact definition who/], {fact => $r->{fact}, definition => $r->{definition}, ts => $r->{ts}, who => $r->{who}, id => {'!=' => $r->{id} } } )->hash) {
		print "$dupe->{fact}\t$dupe->{id}\n";
		print "$r->{fact}\t$r->{id}\n";
		print "deleted id=$dupe->{id}\n";

		$dbh->delete(tablename(), {fact => $r->{fact}, definition => $r->{definition}, ts => $r->{ts}, who => $r->{who}, id => $r->{id} });
	}
} 



