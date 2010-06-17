#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;

my $module     = 'V2::Client';
my $serverPort = 8000;
my $server     = "http://localhost:$serverPort";

use_ok($module) or exit;

can_ok( $module, 'new' );
my $sc = $module->new( url => $server );
isa_ok( $sc, $module );

can_ok( $sc, 'url' );
is( $sc->url(), $server,
    "url() should return server set in 'new()' constructor" );

is( $sc->url("http://localhost:8080"),
    "http://localhost:8080", 'url() should return server in set url()' );

can_ok( $sc, 'ua' );
isa_ok( $sc->ua(), 'LWP::UserAgent' );

