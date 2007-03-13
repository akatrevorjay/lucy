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
use base qw(Lucy::Diamond);
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
	unless ( ( $cmd eq 'google' )
		&& ( defined $Lucy::config->{GoogleApi_Key} ) )
	{

# it is important to return 1 when you want the event to NOT continue to other plugins
# otherwise, 0 or undef will do just fine.
		return 0;
	}
	$where = $where->[0];
	Lucy::debug( 'Google', "query for [$args]", 6 );

	if ( length($args) > 3 ) {
		my $google = Net::Google->new( key => $Lucy::config->{GoogleApi_Key} );
		my $search = $google->search();

		$search->max_results( ( $args =~ s/\s+max=([1-5])$// ) ? $1 : 2 );
		$search->query($args);

		my $i = 1;
		map {
			$lucy->privmsg( $where,
				Lucy::font( 'yellow bold', "$i. " ) . $_->URL() );
			$i++;
		} @{ $search->results() };
		undef $i;

		undef $google;
		undef $search;
	} else {
		$lucy->privmsg( $where,
			Lucy::font( 'red', '!! ' )
			  . 'Searches have a 4 character minimum' );
	}
	
	return 1;
}

1;
