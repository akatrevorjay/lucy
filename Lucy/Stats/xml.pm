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
package Lucy::Stats::xml;
use XML::Smart;
use warnings;
use strict;

sub new {
	my $class = shift;
	return bless {}, $class;
}

sub runTheSilkScreen {
	my $class = shift;
	my $mmm = shift;

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

1;