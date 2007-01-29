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
use Lucy::Stats;
use File::Slurp;
use warnings;
use strict;
use vars qw($VERSION);
$VERSION = "0.42";

my $stats = Lucy::Stats->new();
my $quiet = 1;

# parse each argument as type=filename
for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) {
	my ( $filter, $file );

	if ( $ARGV[$i] =~ /^quiet=([0-1])$/ ) {
		$quiet = $1;
		next;
	} elsif ( $ARGV[$i] =~ /^([\w_-]+)(?:=(.+))?$/ ) {
		$filter = $1;
		if ($2) {
			$file = $2;
		} else {
			$file = 'stdout';
		}
	} else {
		next;
	}

	print "Saving $filter into $file...\n"
	  unless $quiet;

	if ( my $out = $stats->fetch($filter) ) {
		if ( $file eq 'stdout' ) {
			print $out;
		} else {
			write_file( $file, $out );
		}
	}
}
