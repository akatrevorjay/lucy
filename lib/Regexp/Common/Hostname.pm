package Regexp::Common::Hostname;
use warnings;
use strict;
local $^W = 1;

use Regexp::Common qw /pattern clean no_defaults/;

pattern name    => [qw (Hostname)],
        create  => q/(?:(?:(?:(?:[a-zA-Z\d](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?)\.)*(?:[a-zA-Z](?:(?:[a-zA-Z\d]|-)*[a-zA-Z\d])?))|(?:(?:\d+)(?:\.(?:\d+)){3}))/,
        ;

1;
