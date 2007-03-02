#!/usr/bin/perl
# SVN: $Id: lucy.pl 205 2006-05-17 06:29:45Z trevorj $
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
package Lucy;
use warnings;
use strict;
no strict "refs";
use vars qw($VERSION $dbh $sessid $lucy);
$VERSION = "0.5svn";

BEGIN {
	unshift( @INC, "./lib" );
}

use Lucy::Config;
use Lucy::Common;
use Lucy::Sky;
use POE;
use DBIx::Simple;

# grab dbi object
$dbh = DBIx::Simple->connect(
	$config->{DBdsn},
	$config->{DBuser},
	$config->{DBpass},
	{
		RaiseError => 0,
		AutoCommit => 1,
		PrintWarn  => ( $config->{debug_level} > 6 ) ? 1 : 0,
		PrintError => ( $config->{debug_level} > 4 ) ? 1 : 0
	}
  )
  or die "Cannot connect to DB!";

# Automatically reconnect to the db.
#WTF This is mysql only. Does this fix the reconnect issue with MySQL?
$dbh->{mysql_auto_reconnect} = 1;

# Lucy in the Skyyyyy with Diamonds
$lucy = Lucy::Sky->new();

## Diamonds, aka plugins if you're lame
$lucy->add_diamond( @{ $config->{Diamonds} } );

$poe_kernel->run();
exit(0);

# gotta have the session id available
sub sessid {
	return $lucy->session_id;
}

1;
