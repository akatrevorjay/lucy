#!/usr/bin/perl
# SVN: $Id$
# Diamond parent class
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
package Lucy::Diamond;
use POE;
use warnings;
use strict;

sub methods {
	my ( $class, $types ) = @_;
	$class = ref $class || $class;
	$types ||= '';
	my %classes_seen;
	my %methods;
	my @class = ($class);
	no strict 'refs';
	while ( $class = shift @class ) {
		next if $classes_seen{$class}++;
		unshift @class, @{"${class}::ISA"} if $types eq 'all';

#TODO find out why this was needed to be eval'd for Logger alone, and only in newer perl installations.
# Based on methods_via() in perl5db.pl
		for my $method (
			eval {
				grep { not /^[(_]/ and defined &{ ${"${class}::"}{$_} } }
				  keys %{"${class}::"};
			}
		  )
		{
			$methods{$method} = wantarray ? undef : $class->can($method);
		}
	}

	wantarray ? keys %methods : \%methods;
}

##
## What follows is for easy-to-create Diamonds, at the expense of functionality
## - A normal Diamond already more than likely uses these methods, so they
## -   just won't run, since this is a sub-class.
##

### Mmmm. We have been loaded.
sub new {
	my $class = shift;
	my $self = bless {}, $class;
	$self->__init($class);

	eval { $self->init(); };

	return $self;
}

## Create a command map {command}{sub} from the array.
## This is really just to make it easier to make command aliases.
sub __init {
	my ( $self, $class ) = @_;

	$class =~ /([^:]+)$/;
	my $name = $1;
	$self->{__abstract} = 1;
	$self->{__name}     = $name;

	my %commands = %{ $self->commands };
	foreach my $c ( keys %commands ) {
		foreach ( @{ $commands{$c} } ) {
			$self->{__cmd_map}{$_} = $c;
		}
	}
}

sub irc_bot_command {
	unless ( $_[OBJECT]->{__cmd_map}{ $_[ARG3] } ) {
		return undef;
	}

	my ( $self, $lucy, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	$where = $where->[0];

	my $vars = {
		config => $Lucy::config->{Diamond_Config}{ $self->{__name} },
		query  => $args,
		nick   => $nick,
		where  => $where,
	};

	#TODO text replacement mechanism? like %nick%, or %red%this is red%red%
	if ( my $ret =
		eval( 'return $self->' . $self->{__cmd_map}{$cmd} . '($vars);' ) )
	{

		#use Data::Dumper;
		#print Dumper($ret);
		foreach ( eval { @{$ret} } ) {
			$lucy->privmsg(
				$where => Lucy::font( 'yellow bold', "$nick: " ) . $_ );
		}

		return 1;
	} else {
		print $@;
	}

}

1;
