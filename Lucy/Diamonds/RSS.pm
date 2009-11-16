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
#TODO add a !rss command, where $args is something like '$feedname $headlineno'
#		and it will spit out the description
# subclass of PoCo::RSSAggregator to make it diamond-compat
package Lucy::Diamonds::RSS;
use base qw(Lucy::Diamond POE::Component::RSSAggregator);
use POE;
use Cwd;
use warnings;
use strict;
no strict 'refs';

sub tablename { return 'lucy_feeds'; }

### Mmmm. We have been loaded. overrides rssaggregator's to hard-code the params.
sub new {
	my $self = bless {
		alias             => 'rss',
		debug             => ( $Lucy::config->{debug_level} > 7 ) ? 1 : 0,
		_recent_headlines => {},
	  },
	  shift;
	$self->_init();
	foreach (
		$Lucy::dbh->select( $self->tablename, [qw(url name delay enabled)] )
		->hashes )
	{
		next if ( $_->{enabled} eq 'N' );

		# XML::RSS::Feed complains about feed details it doesn't know about.
		delete $_->{enabled};

		Lucy::debug( 'RSS', 'Adding feed [' . $_->{name} . ']', 6 );
		$poe_kernel->post( 'rss', 'add_feed', $_ );
	}
	return $self;
}

# override it to use our own callback
sub response {
	my ( $self, $kernel, $request_packet, $response_packet ) =
	  @_[ OBJECT, KERNEL, ARG0, ARG1 ];
	my ( $req, $feed_name ) = @$request_packet;
	unless ( exists $self->{feed_objs}{$feed_name} ) {
		warn "[$feed_name] Unknown Feed\n";
		return;
	}

	my $rssfeed = $self->{feed_objs}{$feed_name};
	unless ( $rssfeed->can("parse") ) {
		warn "[$feed_name] Unknown Feed, can't parse\n";
		return;
	}

	my $res = $response_packet->[0];
	if ( $res->is_success ) {
		warn "[" . $feed_name . "] Fetched " . $rssfeed->url . "\n"
		  if $self->{debug};
		if ( $rssfeed->parse( $res->content ) ) {

			#TODO can't the above be done by checking the ts???
			for my $headline ( $rssfeed->late_breaking_news ) {

#TODO maybe the recent headlines should be stored in an array to allow for a max recent headlines
				delete $self->{_recent_headlines}{$feed_name}
				  if defined $self->{_recent_headlines}{$feed_name};
				$self->{_recent_headlines}{$feed_name}{url} =
				  $headline->url->as_string;
				$self->{_recent_headlines}{$feed_name}{headline} =
				  $headline->headline;
				$self->{_recent_headline_feed} = $feed_name;
				next if ( defined $self->{_new_feeds}{$feed_name} );

				Lucy::debug(
					'RSS',
					'New headline [' . $feed_name . '] ' . $headline->headline,
					7
				);

				foreach ( keys %{ $Lucy::config->{Channels} } ) {
					$kernel->post(
						Lucy::sessid() => 'privmsg',
						$_,
						'[' . $feed_name . '] ' . $headline->headline
					);
				}
			}
			delete $self->{_new_feeds}{$feed_name}
			  if defined $self->{_new_feeds}{$feed_name};
		}
	} else {
		warn "[!!] Failed to fetch " . $req->uri . "\n";
		$kernel->post( 'rss' => 'pause_feed', $feed_name );

		#TODO does this work?
		$Lucy::dbh->update(
			$self->tablename,
			{ name    => $feed_name },
			{ enabled => 'N' }
		);

		#TODO Feeds should be per-channel, do not just puke them to all of them!
		foreach ( keys %{ $Lucy::config->{Channels} } ) {
			$kernel->post(
				$Lucy::sessid => 'privmsg',
				$_,
				'[' . $feed_name . '] feed failed to fetch. Disabling...'
			);
		}
	}
}

# override this to use our feed package and set the last timestamp
sub _create_feed_object {
	my ( $self, $feed_hash ) = @_;
	warn "[$feed_hash->{name}] Creating XML::RSS::Feed object\n"
	  if $self->{debug};
	$feed_hash->{debug} = $self->{debug} if $self->{debug};

  # only work on 3 headlines at a time, does this help at all with memory usage?
	$feed_hash->{max_headlines} = 1;    # changed to 1
	if ( my $rssfeed = XML::RSS::Feed->new(%$feed_hash) ) {

		#if ( my $rssfeed = Lucy::Diamonds::RSS::Feed->new(%$feed_hash) ) {
		#TODO damn, this needs to use the feed's last timestamp
		$self->{feed_objs}{ $rssfeed->name } = $rssfeed;
		$self->{_new_feeds}{ $feed_hash->{name} } = 1;
	} else {
		warn
"[$feed_hash->{name}] !! Error attempting to create XML::RSS::Feed object\n";
	}
}

sub irc_bot_command {
	my ( $self, $lucy, $kernel, $who, $where, $what, $cmd, $args, $type ) =
	  @_[ OBJECT, SENDER, KERNEL, ARG0, ARG1, ARG2, ARG3, ARG4, ARG5 ];
	$where = $where->[0];
	my $nick = ( split( /[@!]/, $who, 2 ) )[0];
	if (   $cmd eq 'fetch'
		&& $args =~
/^(?:me\s+)?(?:the\s+)?(?:last\s+)?([\w]{3,30})\s+(?:on\s+|from\s+)?([\w]{3,30})$/
	  )
	{
		$1 = 'description' if $1 eq 'desc';
		if ( defined $self->{_recent_headlines}{$2} ) {
			if ( defined $self->{_recent_headlines}{$2}{$1} ) {
				$lucy->yield( privmsg => $where => "$nick: "
					  . $self->{_recent_headlines}{$2}{$1} );
			} else {
				$lucy->yield( privmsg => $where =>
					  "$nick: $2 doesn't know what a $1 is!" );
			}
		} else {
			$lucy->yield( privmsg => $where =>
				  "$nick: I don't know of any feed called $2" );
		}
		return 1;
	} elsif ( $cmd eq 'rss' ) {
		my ( $subcmd, @subargs ) = split / /, $args or return 0;

		if ( $subcmd eq 'list' ) {
			my $feeds = $self->feeds();

			map { $_->{db} = 1; $feeds->{ $_->{name} } = $_; }
			  $Lucy::dbh->select( $self->tablename,
				[qw(url name delay enabled)] )->hashes;

			foreach my $name ( keys %$feeds ) {
				my $f = $feeds->{$name};
				$name .= "*" if exists $f->{db};

				my $append;
				foreach (qw/url delay enabled/) {
					next unless ( exists $f->{$_} );
					$append .= " $_=" . $f->{$_};
				}

				$lucy->yield( privmsg => $where => "$nick: "
					  . "feed: ["
					  . $name . "]"
					  . $append );
			}

			undef $feeds;
		} elsif ( $subcmd eq 'add' ) {
			my $feed = {};
			foreach my $arg (@subargs) {
				if ( $arg =~ /^name=([\w\s]{3,30})$/ ) {
					$feed->{name} = $1;
				} elsif ( $arg =~ /^url=(.{8,128})$/ ) {
					if ( Lucy::Common::isurl($1) ) {
						$feed->{url} = $1;
					} else {
						$lucy->privmsg( $where,
							"$nick : sorry man, but your url is faulty . " );
						return 1;
					}
				}
			}

			# Make sure we got all the params right
			foreach my $s (qw(name url)) {
				unless ( exists $feed->{$s} ) {
					$lucy->privmsg( $where,
						"$nick : your rss feed needs a $s= blah " );
					return 1;
				}
			}

  # for now, we hardcode this at every 30 minutes. This keeps it nice and clean.
			$feed->{delay} = 1800;

			#$feed{userid} = blah;
			Lucy::debug( 'RSS', 'Adding feed [' . $feed->{name} . ']', 6 );
			$kernel->post( 'rss' => 'add_feed', $feed );

			#$feed->{ts} = time;
			#$Lucy::dbh->insert( $self->tablename, $feed );
			undef $feed;
		} elsif ( $subcmd eq 'remove' && $subargs[0] =~ /^[\w\s]{3,30}$/ ) {
			Lucy::debug( 'RSS', 'removing feed [' . $subargs[0] . ']', 6 );

			$kernel->post( 'rss' => 'remove_feed', $subargs[0] );

			#$Lucy::dbh->delete( $self->tablename, {name => $subargs[0]} );
			$lucy->privmsg( $where,
"$nick : ok, I removed it from memory. It will be back when I am restarted though . "
			);
		} elsif ( $subcmd eq 'pause' && $subargs[0] =~ /^[\w\s]{3,30}$/ ) {
			Lucy::debug( 'RSS', 'pausing feed [' . $subargs[0] . ']', 6 );

			$kernel->post( 'rss' => 'pause_feed' => $subargs[0] );
			$Lucy::dbh->update(
				$self->tablename,
				{ enabled => 'N' },
				{ name    => $subargs[0] }
			);
			$lucy->privmsg( $where, "$nick : ok " );
		} elsif ( $subcmd eq 'resume' && $subargs[0] =~ /^[\w\s]{3,30}$/ ) {
			Lucy::debug( 'RSS', 'resuming feed [' . $subargs[0] . ']', 6 );

			$kernel->post( 'rss' => 'resume_feed' => $subargs[0] );
			$Lucy::dbh->update(
				$self->tablename,
				{ enabled => 'Y' },
				{ name    => $subargs[0] }
			);
			$lucy->privmsg( $where, "$nick : ok " );
		}
		return 1;
	}
}

1;
