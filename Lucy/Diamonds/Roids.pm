#!/usr/bin/perl
# SVN: $Id$
# Give Lucy Roids!
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
package Lucy::Diamonds::Roids;
use base qw(Lucy::Diamond);
use POE;
use strict;
use warnings;

# Oh yeah. We need a table name. and I'm so not typing it in a thousand times.
sub tablename { return 'lucy_roids'; }

sub commands {
	return {
		forget   => [qw(forget)],
		unforget => [qw(remember unforget)],
		search   => [qw(factoid whatis roid)],
		history  => [qw(history)],
	};
}

sub init {
	my $self = shift;

	my $config = $self->diamond_config;
	$self->{fact_regex} = $config->{fact_regex} || '[\w\s]{3,32}';
	$self->{trigger_regex} = $config->{trigger_regex}
	  || 'is|are|tastes|smells|feels|sounds|says|fucks|rapes|murders|kills|hates|loves';
	$self->{allowed_mod_regex} = $config->{allowed_mod_regex}
	  || '(?:\s+(id|who|ts|forgotten)=([\w_\-]+))';
}

# Forget/hide a roid
#TODO make this only forget the latest one, ie, sort by ts, then limit 1.
sub forget {
	my ( $self, $v ) = @_;
	return undef
	  unless my ( $fact, $f_key, $f_val ) =
		  $v->{args} =~
		  /^\s*($self->{fact_regex})$self->{allowed_mod_regex}?\s*$/;
	my @msg;

	my $f_args;
	if ($f_key) {
		Lucy::debug( "Roids",
			"forget: '$fact' is being forgot with $f_key=$f_val", 7 );
		$f_args = { fact => $fact, "$f_key" => $f_val };
	} else {
		Lucy::debug( "Roids", "forget: '$fact' is being forgot", 7 );
		$f_args = $fact;
	}

	if ( $self->_forget_roid($f_args) ) {
		Lucy::debug( "Roids", "forget: $fact", 7 );
		push( @msg, "Ok, I forgot $fact" );
	}

	return \@msg;
}

# Forget/hide a roid
sub unforget {
	my ( $self, $v ) = @_;
	return undef
	  unless my ( $fact, $f_key, $f_val ) =
		  $v->{args} =~
		  /^\s*($self->{fact_regex})$self->{allowed_mod_regex}?\s*$/;
	my @msg;

	my $f_args;
	if ($f_key) {
		Lucy::debug( "Roids",
			"unforget: '$fact' is being unforgot with $f_key=$f_val", 7 );
		$f_args = { fact => $fact, "$f_key" => $f_val };
	} else {
		Lucy::debug( "Roids", "unforget: '$fact' is being unforgot", 7 );
		$f_args = $fact;
	}

	if ( $self->_unforget_roid($f_args) ) {
		push( @msg, "Ok, I remembered $fact" );
	}

	return \@msg;
}

# Look for roids. God help you if you find them.
sub search {
	my ( $self, $v ) = @_;
	my $what = $v->{args};
	my $max_results = ( $what =~ s/\s+max=(\d)\s*$// ) ? $1 : 3;
	return undef
	  unless my ( $fact, $f_key, $f_val ) =
		  $what =~ /^\s*($self->{fact_regex})$self->{allowed_mod_regex}?\s*$/;
	my @msg;

	my $f_args;
	if ($f_key) {
		Lucy::debug(
			"Roids",
			"search: [$fact] with [$f_key]=[$f_val] max_results=[$max_results]",
			7
		);
		$f_args = { fact => $fact, "$f_key" => $f_val };
	} else {
		Lucy::debug( "Roids", "search: [$fact] max_results=[$max_results]", 7 );
		$f_args = $fact;
	}

	if ( my @roids = $self->_search_roids( $f_args, $max_results ) ) {
		my $i = 0;
		foreach (@roids) {
			next unless UNIVERSAL::isa( $_, 'HASH' ) && defined $_->{fact};
			$i++;

			my $timesince =
			  ( $_->{ts} > 0 )
			  ? ': ' . Lucy::timesince( $_->{ts} ) . ' ago'
			  : '';
			push( @msg,
				    "$i. "
				  . $_->{fact} . ' '
				  . $_->{definition} . ' ['
				  . $_->{who}
				  . "$timesince] id="
				  . $_->{id}
				  . " forgot="
				  . $_->{forgotten} );
		}
	}

	return \@msg;
}

# Show roid history
sub history {
	my ( $self, $v ) = @_;
	my $what = $v->{args};
	my $max_results = ( $what =~ s/\s+max=(\d)\s*$// ) ? $1 : 3;
	return undef
	  unless my ( $fact, $f_key, $f_val ) =
		  $what =~ /^\s*($self->{fact_regex})$self->{allowed_mod_regex}?\s*$/;
	my @msg;

	my $f_args;
	if ($f_key) {
		Lucy::debug(
			"Roids",
"history: [$fact] with [$f_key]=[$f_val] max_results=[$max_results]",
			7
		);
		$f_args = { fact => $fact, "$f_key" => $f_val };
	} else {
		Lucy::debug( "Roids", "history: [$fact] max_results=[$max_results]",
			7 );
		$f_args = { fact => $fact };
	}

	if ( my @roids = $self->_search_roids( $f_args, $max_results ) ) {
		my $i = 0;
		foreach (@roids) {
			next unless UNIVERSAL::isa( $_, 'HASH' ) && defined $_->{fact};
			$i++;

			my $timesince =
			  ( $_->{ts} > 0 )
			  ? ': ' . Lucy::timesince( $_->{ts} ) . ' ago'
			  : '';
			push( @msg,
				    "$i. "
				  . $_->{fact} . ' '
				  . $_->{definition} . ' ['
				  . $_->{who}
				  . "$timesince] id="
				  . $_->{id}
				  . " forgot="
				  . $_->{forgotten} );
		}
	}

	return \@msg;
}

sub irc_public {
	my ( $self, $lucy, $who, $where, $what ) =
	  @_[ OBJECT, SENDER, ARG0, ARG1, ARG2 ];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	my $botnick = $lucy->nick_name();
	$where = $where->[0];

	my ( $fact, $f_key, $f_val, $def );

	if ( ( $fact, $def ) =
		$what =~ /^($self->{fact_regex})\s+((?:$self->{trigger_regex}).+)\s*$/ )
	{

		# We now save EVERYTHING unless it's ignored.
		if (
			my $r = $self->_get_roid(
				{
					-nest =>
					  [
						{
							forgotten  => 0,
							fact       => $fact,
							definition => 'is ignored',
						},
						{ fact => $fact, definition => $def }
					  ]
				}
			)
		  )
		{
			Lucy::debug( "Roids",
				"irc_public: [$fact] is ignored in db, or definition already exists. not saving.", 7 );
		} else {
			$self->_put_roid( $fact, $def, $nick, time );
		}

	} elsif ( ( $fact, $f_key, $f_val ) =
		$what =~
		/^forget\s+($self->{fact_regex})$self->{allowed_mod_regex}?\s*$/ )
	{
		my $f_args;
		if ($f_key) {
			Lucy::debug(
				"Roids",
"irc_public: forget: '$fact' is being forgot with $f_key=$f_val",
				7
			);
			$f_args = { forgotten => 0, fact => $fact, "$f_key" => $f_val };
		} else {
			Lucy::debug( "Roids", "irc_public: forget: '$fact' is being forgot",
				7 );
			$f_args = $fact;
		}

		if ( $self->_forget_roid($f_args) ) {
			$lucy->yield( privmsg => $where => "$nick: Ok, I forgot $fact" );
			return 1;
		}

	} elsif ( ( $fact, $f_key, $f_val ) =
		$what =~
/^(?:unforget|remember)\s+($self->{fact_regex})$self->{allowed_mod_regex}?\s*$/
	  )
	{
		my $f_args;
		if ($f_key) {
			Lucy::debug(
				"Roids",
"irc_public: unforget: '$fact' is being unforgot with $f_key=$f_val",
				7
			);
			$f_args = { forgotten => 1, fact => $fact, "$f_key" => $f_val };
		} else {
			Lucy::debug( "Roids",
				"irc_public: unforget: '$fact' is being unforgot", 7 );
			$f_args = $fact;
		}

		if ( $self->_unforget_roid($f_args) ) {
			$lucy->yield(
				privmsg => $where => "$nick: Ok, I remembered $fact" );
			return 1;
		}
	} elsif ( ($fact) = $what =~ /^($self->{fact_regex})\?.*$/ ) {
		if ( my $r = $self->_get_roid($fact) ) {
			return
			  if (
				$self->_get_roid(
					{
						forgotten  => 0,
						fact       => $fact,
						definition => 'is ignored'
					}
				)
			  );
			my $append =
			  ( $r->{ts} > 0 )
			  ? ': ' . Lucy::timesince( $r->{ts} ) . ' ago'
			  : '';
			$append .= '] id=' . $r->{id};

			$lucy->yield( privmsg => $where => "$nick: $fact "
				  . $r->{definition} . ' ['
				  . $r->{who}
				  . $append );

			return 1;
		}
	}
}

##
## Helper functions
##

sub _forget_roid {
	my $self = shift;
	my $fact = shift;
	Lucy::debug( "Roids", "_forget_roid: $fact", 7 );

	my $where =
	  ( UNIVERSAL::isa( $fact, 'HASH' ) )
	  ? $fact
	  : { fact => $fact, forgotten => 0 };

	if ( my $roid = $self->_get_roid($fact) ) {
		if (
			$Lucy::dbh->update(
				$self->tablename,
				{ forgotten => 1 },
				{ id        => $roid->{id} }
			)
		  )
		{
			return 1;
		}
	}
}

sub _unforget_roid {
	my $self = shift;
	my $fact = shift;
	Lucy::debug( "Roids", "_unforget_roid: $fact", 7 );

	my $where =
	  ( UNIVERSAL::isa( $fact, 'HASH' ) )
	  ? $fact
	  : { fact => $fact, forgotten => 1 };

	if ( my $roid = $self->_get_roid($where) ) {
		if (
			$Lucy::dbh->update(
				$self->tablename,
				{ forgotten => 0 },
				{ id        => $roid->{id} }
			)
		  )
		{
			return 1;
		}
	}
}

sub _get_roid {
	my $self  = shift;
	my $fact  = shift;
	my $grab  = shift || [qw/id fact definition who ts forgotten/];
	my $order = shift || 'rand()';
	Lucy::debug( "Roids", "_get_roid: $fact", 7 );

	$fact = { forgotten => 0, fact => $fact }
	  unless ( UNIVERSAL::isa( $fact, 'HASH' ) );
	my ( $where, @bind_vars ) = $Lucy::dbh->abstract->where($fact);

	if (
		my $roid = $Lucy::dbh->query(
			"SELECT "
			  . join( ', ', @{$grab} )
			  . " FROM "
			  . $self->tablename
			  . " $where ORDER BY $order LIMIT 1",
			@bind_vars
		)->hash
	  )
	{
		return $roid unless $roid->{definition} eq 'is ignored';
	}
}

sub _search_roids {
	my $self        = shift;
	my $fact        = shift;
	my $max_results = shift || 3;
	my $grab        = shift || [qw/id fact definition who ts forgotten/];
	my $order       = shift || 'rand()';
	Lucy::debug( "Roids", "_search_roid: $fact", 7 );

	my ( $where, @bind_vars );
	if ( UNIVERSAL::isa( $fact, 'HASH' ) ) {
		( $where, @bind_vars ) = $Lucy::dbh->abstract->where($fact);
	} else {
		$where = "WHERE definition != 'is ignored' AND forgotten = 0 "
		  . " AND MATCH (fact,definition,who) AGAINST (?)";
		@bind_vars = ($fact);
	}

	my $q = $Lucy::dbh->query(
		"SELECT "
		  . join( ', ', @{$grab} )
		  . " FROM "
		  . $self->tablename
		  . " $where"
		  . " ORDER BY $order LIMIT $max_results",
		@bind_vars
	);

	if ( my @roids = $q->hashes ) {
		return @roids;
	}
}

sub _put_roid {
	my $self = shift;
	my (%r);
	$r{fact}       = shift || return;
	$r{definition} = shift || return;
	$r{who}        = shift || return;
	$r{ts}         = shift || return;
	$r{forgotten}  = shift || 0;
	Lucy::debug( "Roids", "_put_roid: $r{fact}", 7 );

	$Lucy::dbh->insert( $self->tablename, \%r );
}

1;
