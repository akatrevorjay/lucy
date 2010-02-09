#!/usr/bin/perl
# SVN: $Id$
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
package Lucy::Diamonds::Rive;
use base qw(Lucy::Diamond);
use POE;
# Perl 5.10.0 requires this to be loaded as well as IO::Socket, or the module does some weird things where it won't load it's own code,
#  not to mention $self->methods stops working.
use RiveScript;
use warnings;
use strict;

### LOCKNESSSZZZ MONSTA IS MAI BITCH
sub irc_bot_command {
	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];
	Lucy::debug( 'RiveScript', "got command $cmd", 7 );

	my $out;
	if ( my $msg = $self->get_reply( $nick, $cmd . ' ' . $args ) ) {
		$out = Lucy::font( 'bold', $nick ) . ": " . $msg;
	} else {
		$out = Lucy::font( 'bold', $nick ) . ": ERR: What the Fuck?";
	}

	$lucy->yield( privmsg => $where => $out );
}

### Mmmm. We have been loaded.
sub new {
	my $rs = new RiveScript;
	$rs->loadDirectory ( './replies/' );
	$rs->setVariable ( master => $Lucy::config->{Maintainer} );
	$rs->setVariable ( xrs => './replies/x.rs' );
	$rs->sortReplies;
	my $self = bless { priority => 9,
			   rs => $rs }, shift;
	return $self;
}

### Heart and soul, Yo.
sub get_reply {
	my ( $self, $who, $msg ) = @_;

	my $out = $self->{rs}->reply( $who, $msg );

	return $out;
}

1;
