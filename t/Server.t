#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use LWP::UserAgent;
use HTTP::Request;
use YAML::Tiny;

BEGIN { use_ok($_) for qw(Server Resource Agenda Booking DateTime) }

my $server_port = 8000;
my $server      = "http://localhost:$server_port";

my $pid = Server->new($server_port)->background();

# Testing resource list
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("$server/resources");
    ok( $res->is_success, "$server/resources" );

    my $yaml = YAML::Tiny->new();
    $yaml->[0] = {};
    ok( $res->content eq $yaml->write_string() . "\n", "resource list" );
}

# Angel commented out the following tests:
# Server should not receive parameters out of API (?).
# This kind of requests should be encapsulated into a future
# "WebFrontendClient" (or similar) class, which translated
# "<form>" requests into API REST calls and API REST responses
# into (X)HTML (or XML+XSLT, etc). (?)
#
# Testing resource creation via form
#{
#    my $ua  = LWP::UserAgent->new();
#    my $res = $ua->post("$server/resource",
#                        { id => 1, desc => 'desc 1', gra => 'gra 1' });
#    ok($res->is_success, $res->content);
#}
#
# Testing resource retrieval
#{
#    my $ua  = LWP::UserAgent->new();
#    my $res = $ua->get("$server/resource/1");
#    ok($res->is_success, $res->content);
#}

# Testing resource creation via XML
my $resource_as_xml;
{
    my $b1 = Booking->new(
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 10,
            second => 0
        ),
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 10,
            second => 59
        )
    );
    my $b2 = Booking->new(
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 11,
            second => 0
        ),
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 11,
            second => 59
        )
    );
    my $ag = Agenda->new();
    $ag->append($b1);
    $ag->append($b2);
    my $resource = Resource->new( 2, 'desc 2 2', 'gra 2 2', $ag );

    my $req = HTTP::Request->new( POST => "$server/resource" );
    $req->content_type('text/xml');
    $resource_as_xml = $resource->to_xml();
    $req->content($resource_as_xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    my $r   = Resource->from_xml( $res->content );

    #ok($res->is_success, $res->content);
    ok( $r->{id} eq '2' && $r->{desc} eq 'desc 2 2',
        "resource creation $res->content"
    );
}

# Testing resource retrieval
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("$server/resource/2");
    ok( $res->is_success && $res->content =~ /\Q$resource_as_xml/,
        "resource retrieval $res->content" );
}

# Testing resource removal
{
    my $req = HTTP::Request->new( DELETE => "$server/resource/1" );
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    ok( $res->is_success, $res->content );

    $res = $ua->get("$server/resource/1");
    ok( !$res->is_success && $res->content =~ /Resource does not exist/,
        "resource removal $res->content" );
}

END {
    kill 3, $pid;
    unlink </tmp/*.db>;
}
