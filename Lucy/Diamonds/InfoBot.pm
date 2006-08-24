#!/usr/bin/perl
# SVN: $Id: InfoBot.pm 205 2006-05-17 06:29:45Z trevorj $
# InfoBot functionality
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
package Lucy::Diamonds::InfoBot;
use POE;
use strict;
use warnings;

# Oh yeah. We need a table name. and I'm so not typing it in a thousand times.
sub tablename { return 'lucy_factoids'; }

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless { InfoBot => {} }, $class;
}

### Public message event
sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	if ( $cmd eq 'forget' ) {
		if ( my $f =
			$Lucy::dbh->select( $self->tablename, ['id'], { fact => $args } )
			->hash )
		{
			$Lucy::dbh->delete( $self->tablename, { id => $f->{id} } );
			$lucy->privmsg( $where, "$nick: I forgot $args" );
		} else {
			$lucy->privmsg( $where,
				"$nick: Look, I don't know wtf $args is/are, nor do I care!" );
		}
	} elsif ( ( $cmd eq 'what' )
		&& ( my ($fact) = $args =~ /^(?:is|are) ([\w ]{3,30})$/ ) )
	{
		if (
			my $f = $Lucy::dbh->select(
				$self->tablename,
				[ 'definition', 'who' ],
				{ fact => $fact }
			)->hash
		  )
		{
			$lucy->privmsg( $where,
				"$nick: $fact " . $f->{definition} . " [" . $f->{who} . "]" );
		} else {
			$lucy->privmsg( $where,
				"$nick: Look, I don't know wtf $fact is, nor do I care!" );
		}
	} elsif ( $cmd eq 'factoid' ) {
		my $q;

		#TODO I don't like this here. it belongs inside of the if.
		my $max_results = 3;
		if ( $args =~ s/\s+max=([1-5])$// ) {
			$max_results = $1;
		}

		if ( $args =~ /^[\w ]{3,30}$/ ) {

			# search the factoids for $args
			$q = $Lucy::dbh->query(
				"SELECT fact, definition, who FROM "
				  . $self->tablename
				  . " WHERE MATCH (fact,definition) AGAINST (?) LIMIT "
				  . $max_results,
				$args
			);
		} else {

			# no $args, return a random one (fast random row on larger tables)
			$q = $Lucy::dbh->query(
				    "SELECT fact,definition,who FROM "
				  . $self->tablename
				  . " AS r1 JOIN
			(SELECT ROUND(RAND() * (SELECT MAX(id) FROM "
				  . $self->tablename . ")) AS id) AS r2
			WHERE r1.id >= r2.id ORDER BY r1.id ASC LIMIT 1"
			);
		}

		# grab the returned factoids
		for my $f ( $q->hashes ) {
			$lucy->privmsg( $where,
				$f->{who} . " says " . $f->{fact} . " " . $f->{definition} );
		}
	} else {
		return 0;
	}
}

sub irc_public {
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	my $botnick = $lucy->nick_name();
	$where = $where->[0];

	my ( $fact, $def );
	if ( ( $fact, $def ) = $what =~ /^(\w{3,30})\s+((?:is|are).+)\s*$/ ) {
		$fact =~ s/\_/ /g;
		$Lucy::dbh->insert( $self->tablename,
			{ fact => $fact, definition => $def, who => $nick, ts => time } );
	} elsif ( ($fact) = $what =~ /^forget ([\w\s]{3,30})\s*$/ ) {
		$fact =~ s/\_/ /g;
		if ( my $f =
			$Lucy::dbh->select( $self->tablename, ['id'], { fact => $fact } )
			->hash )
		{
			$Lucy::dbh->delete( $self->tablename, { id => $f->{id} } );
			$lucy->privmsg( $where, "$nick: I forgot $fact" );
		}
	} elsif ( ($fact) = $what =~ /^([\w\s]{3,30})\?+\s*$/ ) {
		if (
			my $f = $Lucy::dbh->select(
				$self->tablename,
				[ 'definition', 'who' ],
				{ fact => $fact }
			)->hash
		  )
		{
			unless ( $f->{definition} eq 'is ignored' ) {
				$lucy->privmsg( $where,
					    "$nick: $fact "
					  . $f->{definition} . ' ['
					  . $f->{who}
					  . ']' );
			}
		}
	}
	return 0;
}

1;
