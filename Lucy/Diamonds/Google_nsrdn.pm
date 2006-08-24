#!/usr/bin/perl
# SVN: $Id: Google.pm 174 2006-05-01 21:47:48Z trevorj $
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
package Lucy::Diamonds::Google;
use POE;
use Net::Google;
use warnings;
use strict;

#use Net::Google::Spelling;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	unless ( ( $cmd eq /wisdom|nasrudin|nasreddin/ )
		&& ( defined $Lucy::config->{GoogleApi_Key} ) )
	{

# it is important to return 0 when you want the event to continue to other plugins
		return 0;
	}
	$where = $where->[0];
	Lucy::debug( 'Google', "query for comedic epiphanies", 6 );

	my $google = Net::Google->new( key => $Lucy::config->{GoogleApi_Key} );
	my $search = $google->search();

	$search->query($cmd);

	my $i = rand(999);
	map {
		$lucy->privmsg( $where,
			Lucy::font( 'green invert', "$i. " ) . $_->URL() );
	} @{ $search->results() };
	undef $i;
		
	undef $google;
	undef $search;
}

1;
