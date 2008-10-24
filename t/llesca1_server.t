#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use LWP::UserAgent;

BEGIN { use_ok($_) for qw(Server Resource) };


my $pid = Server->new(8000)->background();
my $ua  = LWP::UserAgent->new();

my $res = $ua->get('http://localhost:8000/resources');

ok($res->is_success);

my $yaml = YAML::Tiny->new();
$yaml->[0] = {};
ok($res->content eq $yaml->write_string() . "\n");

END { kill 3, $pid; }
