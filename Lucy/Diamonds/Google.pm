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
package Lucy::Diamonds::Google;
use base qw(Lucy::Diamond);
use warnings;
use strict;

sub commands {
	return {
		search => [qw(google g goog search)],
		calc   => [qw(googlecalc gcalc calc)],
		translate =>
		  [qw(trans gtrans googtrans gtranslate translate translator)],
		googlism => [qw(googlism spewshit)],
		weather  => [qw(weather gweather)],
	};
}

use Google::Search;

sub search {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'Google', 'query for [' . $v->{args} . ']', 6 );

	my $max_results = 2;
	if ( $v->{args} =~ s/\s+max=([1-5])$// ) {
		$max_results = $1;
	}

	$v->{config}{q} = $v->{args};
	my $search = Google::Search->Web( %{ $v->{config} } );
	my $result = $search->first;

	my $i = 1;
	while ($result) {
		last if ( $i > $max_results );

		push( @msg,
			Lucy::font( 'bold', $result->number . '.' ) . " " . $result->uri );
		$i++;
		$result = $result->next;
	}
	undef $search;
	return undef if ( $i == 1 );

	return \@msg;
}

use WWW::Google::Calculator;

sub calc {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'GoogleCalculator', 'query for [' . $v->{args} . ']', 6 );

	my $calc = WWW::Google::Calculator->new;
	push( @msg, $calc->calc( $v->{args} ) );
	undef $calc;

	return \@msg;
}

use Weather::Google;

sub weather {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'GoogleWeather', 'query for [' . $v->{args} . ']', 6 );

	my $wg      = Weather::Google->new( $v->{args} );
	my $current = $wg->current;
	return unless defined($current->{temp_f}) && length($current->{temp_f}) > 0;
	
	push( @msg,
		    'Weather for '
		  . $v->{args} . ': '
		  . $current->{temp_f} . 'F/'
		  . $current->{temp_c}
		  . 'C; '
		  . $current->{wind_condition}
		  . '; '
		  . $current->{humidity}
		  . '; Conditions: '
		  . $current->{condition} );

	undef $wg;
	return \@msg;
}

use WebService::Google::Language;

sub translate {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'GoogleTranslator', 'query for [' . $v->{args} . ']', 6 );

	my $glang  = WebService::Google::Language->new( %{ $v->{config} } );
	my $result = $glang->translate( $v->{args} );

	if ( $result->error ) {
		push( @msg,
			$result->message
			  . Lucy::font( 'red bold', ' [error=' . $result->code . ']' ) );
	} else {
		push( @msg,
			$result->translation
			  . Lucy::font( 'yellow bold', ' [lang=' . $result->language . ']' )
		);
	}

	#  $result = $service->detect('Bonjour tout le monde');
	#  printf "Detected language: %s\n", $result->language;
	#  printf "Is reliable:       %s\n", $result->is_reliable ? 'yes' : 'no';
	#  printf "Confidence:        %s\n", $result->confidence;

	undef $glang;
	return \@msg;
}

use WWW::Search;

sub googlism {
	my ( $self, $v ) = @_;
	my @msg;

	Lucy::debug( 'Googlism', 'query for [' . $v->{args} . ']', 6 );

	my $max_results = 2;
	if ( $v->{args} =~ s/\s+max=([1-5])\s*// ) {
		$max_results = $1;
	}

	my $type = 'what';
	if ( $v->{args} =~ s/\s+type=(who|what|where|when)\s*// ) {
		$type = $1;
	}

	my $search = WWW::Search->new( 'Googlism', %{ $v->{config} } );
	$search->native_query( WWW::Search::escape_query( $v->{args} ),
		{ type => 'who' } );

	my $i = 1;
	while ( my $result = $search->next_result() ) {
		if ( $i > $max_results ) {
			last;
		}

		push( @msg, $result );
		$i++;
	}
	if ( $i == 1 ) {
		return undef;
	}

	return \@msg;
}

1;
