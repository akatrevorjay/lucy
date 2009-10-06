#!/usr/bin/perl
# SVN: $Id$
# Weather diamond, uses weather.com api
# NEEDS - A weather.com partnerid and licensekey. They are freely available
#         from weather.com.
#TODO Make it remember the user's last weather code, in the same manner as lucy_user_seen table
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
package Lucy::Diamonds::Weather;
use base qw(Lucy::Diamond);
use POE;
use Weather::Com::Simple;
use Cwd;
use warnings;
use strict;

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	return bless {}, $class;
}

sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	unless ( ( $cmd eq 'weather' )
		&& ( defined $Lucy::config->{Diamonds}{Weather}{license} )
		&& ( defined $Lucy::config->{Diamonds}{Weather}{partner_id} ) )
	{
		return 0;
	}
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	Lucy::debug( 'Weather', "query for [$args]", 6 );

	if ( length($args) > 2 ) {

		# grab weather object
		my $sweather = Weather::Com::Simple->new(
			'cache'      => cwd() . '/db/weather',
			'partner_id' => $Lucy::config->{Diamonds}{Weather}{partner_id},
			'license'    => $Lucy::config->{Diamonds}{Weather}{license},
			'place'      => $args,
		);
		if ( defined $sweather ) {
			my $w = $sweather->get_weather();
			if ( defined $w->[0]->{place} ) {

			  # WeCo::Simple returns an array of locations matching the location
			  # We just use the first result.
				$lucy->privmsg( $where,
					    "$nick: Weather for "
					  . $w->[0]->{place} . " is "
					  . $w->[0]->{fahrenheit} . "F/"
					  . $w->[0]->{celsius} . "C" . "; "
					  . $w->[0]->{conditions} . "; "
					  . $w->[0]->{wind}
					  . "; last updated at "
					  . $w->[0]->{updated} );

				undef $w;
			} else {
				$lucy->privmsg( $where,
					"$nick: [$args] was not found to be a suitable location" );
			}
			undef $sweather;
		}
	} else {
		$lucy->privmsg( $where, "$nick: syntax is !weather [location]" );
	}

	return 1;
}

1;
