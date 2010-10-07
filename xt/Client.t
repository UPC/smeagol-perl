#!/usr/bin/perl

use strict;
use warnings;

#use Data::Dumper;

use Test::More tests => 5;

my $module     = 'V2::Client';
my $serverPort = 3000;
my $server     = "http://localhost:$serverPort";

use_ok($module);

my $sc = new_ok( $module => [ 'url', $server ] );

can_ok( $sc, qw(url ua) );

is( $sc->url(), $server,
    "url() should return server set in 'new()' constructor" );

isa_ok( $sc->ua(), 'LWP::UserAgent' );

note 'UserAgent is: ' . $sc->ua->agent;

