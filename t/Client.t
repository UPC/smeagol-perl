#!/usr/bin/perl

use Test::More tests => 2;

use strict;
use warnings;

BEGIN { use_ok("Client") }

eval { Client::_client_call( "localhost", "/", 80, "FAIL" ); };

ok( $@ =~ /Invalid Command/ );

