#!/usr/bin/perl
# SVN: $Id: Songs.pm 200 2006-05-15 03:23:16Z trevorj $
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
use POE;
use LWP::Simple;
use XML::Smart;
use warnings;
use strict;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

### Let's try to do something interesting now
sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	if (
		( $cmd =~ /^(?:lastfm|songs?)$/ )
		&& ( my ( $swho, $ssong ) =
			$args =~ /^(\w{3,30})(?:\s+t?(?:rack\=)?(\d))?$/ )
	  )
	{
		### If the track number is provided, use that
		my $ssong = 0 unless defined $ssong;

		Lucy::debug( "Songs",
			"[$nick] requested recent track $ssong of [$swho]", 6 );
		my ( $content, $url );

		# Cool people with no need for lastfm
		if ( $swho eq 'echoline' ) {
			$url     = "http://eli.neoturbine.net/song";
			$content = get $url;

			# Else, try audioscrobbler/lastfm
		} elsif (
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
				    Lucy::font( 'bold', $track->{artist} ) . " - "
				  . Lucy::font( 'bold', $track->{name} );
			}
			undef $XML;
		}
		### If any content was found, display it in a sensible fashion
		if ( defined $content ) {
			my @r = (
				"$swho is listening to $content",
				"$swho is jammin' out to $content",
				"$swho is rockin' out to $content"
			);
			$lucy->privmsg( $where,
				Lucy::font( 'yellow', $nick ) . ': '
				  . $r[ int rand( $#r + 1 ) ] );
		} else {
			my @r = (
				"suggests the beatles to $nick",
				"suggests QOTSA [Queens of the Stone Age]",
				"demands some floyd!"
			);
			$lucy->yield( ctcp => $where => 'ACTION' => $r[ int rand( $#r + 1 ) ] );
		}
		return 1;
	}
}

1;
