#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use LWP::UserAgent;
use HTTP::Request;
use YAML::Tiny;

BEGIN { use_ok($_) for qw(Server Resource Agenda Booking DateTime) }

my $server_port = 8000;
my $server      = "http://localhost:$server_port";

my $pid = Server->new($server_port)->background();

# Testing retrieve empty resource list
{
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("$server/resources");
    ok( $res->is_success, "$server/resources" );
    ok( $res->content eq "<resources></resources>\n", $res->content );

    #"retrieve empty resource list");
}

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
    ok( $res->is_success, "resource retrieval status" );
    my $r = Resource->from_xml( $res->content );
    ok( ( defined $r ) && $r->{id} eq '2',
        "resource retrieval $res->content"
    );
}

# Testing resource removal
{
    my $req = HTTP::Request->new( DELETE => "$server/resource/2" );
    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);
    ok( $res->is_success, $res->content );

    $res = $ua->get("$server/resource/1");
    ok( $res->code == 404, "resource removal $res->content" );

    #ok( (!$res->is_success) && $res->content =~ /Resource #2 does not exist/,
    #    "resource removal $res->content" );
}

END {
    kill 3, $pid;
    unlink </tmp/*.db>;
}
