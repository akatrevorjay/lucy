#!/usr/bin/perl
# SVN: $Id: Common.pm 206 2006-05-19 03:51:55Z trevorj $
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

1;
