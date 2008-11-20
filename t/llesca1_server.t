#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use LWP::UserAgent;
use HTTP::Request;

BEGIN { use_ok($_) for qw(Server Resource) };

my $server = 'http://localhost:8000';

my $pid = Server->new(8000)->background();

# Testing resource list
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("$server/resources");
    ok($res->is_success);

    my $yaml = YAML::Tiny->new();
    $yaml->[0] = {};
    ok($res->content eq $yaml->write_string() . "\n");
}

# Testing resource creation via form
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->post("$server/resource",
                        { id => 1, desc => 'desc 1', gra => 'gra 1' });
    ok($res->is_success, $res->content);
}

# Testing resource retrieval
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("$server/resource/1");
    ok($res->is_success, $res->content);
}

# Testing resource creation via XML
my $resource_as_xml;
{
    my $resource = Resource->new(2, 'desc 2 2', 'gra 2 2');

    my $req = HTTP::Request->new(POST => "$server/resource");
    $req->content_type('text/xml');
    $resource_as_xml = $resource->to_xml();
    $req->content($resource_as_xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    ok($res->is_success, $res->content);
}

# Testing resource retrieval
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("$server/resource/2");
    ok($res->is_success && $res->content =~ /\Q$resource_as_xml/, $res->content);
}

# Testing resource removal
{
    my $req = HTTP::Request->new(DELETE => "$server/resource/1");
    my $ua = LWP::UserAgent->new();
    my $res = $ua->request($req);
    ok($res->is_success, $res->content);

    $res = $ua->get("$server/resource/1");
    ok(!$res->is_success && $res->content =~ /Resource does not exist/,
       $res->content);
}

END { kill 3, $pid; }
