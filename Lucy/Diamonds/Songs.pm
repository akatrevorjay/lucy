#!/usr/bin/perl
# SVN: $Id$
# Changelog
# trevorj - added audioscrobbler support
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
package Lucy::Diamonds::Songs;
use base qw(Lucy::Diamond);
use warnings;
use strict;
use XML::Smart;

sub commands {
	return { lastfm_recent_track => [qw(lastfm song songs)], };
}

### Let's try to do something interesting now
sub lastfm_recent_track {
	my ( $self, $v ) = @_;
	my @msg;

	if ( my ( $swho, $ssong ) =
		$v->{args} =~ /^(\w{3,30})(?:\s+t?(?:rack\=)?(\d))?$/ )
	{
		### If the track number is provided, use that
		my $ssong = 0 unless defined $ssong;

		Lucy::debug( "Songs",
			'[' . $v->{nick} . "] requested recent track $ssong of [$swho]",
			6 );
		my ( $content, $url );

		if (
			my $XML = XML::Smart->new(
				"http://ws.audioscrobbler.com/1.0/user/$swho/recenttracks.xml")
		  )
		{
			$XML = $XML->cut_root;

			# we only want the first track
			my $track = $XML->{track}[$ssong];

			# artist|name are never undef, so how do I check this better?
			if (   length( $track->{artist} ) > 0
				&& length( $track->{name} ) > 0 )
			{
				$content =
				    Lucy::font( 'green bold', $track->{artist} ) . " - "
				  . Lucy::font( 'blue bold', $track->{name} );
			}
			undef $XML;
		}
		### If any content was found, display it in a sensible fashion
		if ( defined $content ) {
			my $swho = Lucy::font( 'bold', $swho );
			my @r = (
				"$swho is listening to $content",
				"$swho is jammin' out to $content",
				"$swho is rockin' out to $content"
			);
			push( @msg, $r[ int rand( $#r + 1 ) ] );
		} else {
			my @r = (
				"suggests the beatles to " . $v->{nick},
				"suggests QOTSA [Queens of the Stone Age]",
				"demands some floyd!"
			);
			push( @msg, $r[ int rand( $#r + 1 ) ] );
		}
		return \@msg;
	}
}

1;
