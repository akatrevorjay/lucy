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
use warnings;
use strict;
use vars qw($VERSION);
$VERSION = "0.42";

my $type = $ARGV[0] || 'xml';
my $stats = Lucy::Stats->new();
print $stats->fetch($type);
