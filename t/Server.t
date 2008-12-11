#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 13;
use LWP::UserAgent;
use HTTP::Request;

BEGIN { use_ok($_) for qw(Server Resource Agenda Booking DateTime) }

my $server_port = 8000;
my $server      = "http://localhost:$server_port";

my $pid = Server->new($server_port)->background();

# Auxiliary routine to encapsulate server requests
sub smeagol_request {
    my ( $method, $url, $xml ) = @_;

    my $req = HTTP::Request->new( $method => $url );

    $req->content_type('text/xml');
    $req->content($xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res;
}

# Testing retrieve empty resource list
{
    my $res = smeagol_request( 'GET', "$server/resources" );
    ok( $res->is_success, 'resource list retrieval status' );
    ok( $res->content eq "<resources></resources>\n",
        "resource list content $res->content"
    );
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
    my $resource = Resource->new( 'desc 2 2', 'gra 2 2', $ag );

    my $res
        = smeagol_request( 'POST', "$server/resource", $resource->to_xml() );
    ok( $res->is_success, "resource creation status $res->status" );

    my $r = Resource->from_xml( $res->content );
    ok( $r->description eq $resource->description,
        "resource creation content $res->content"
    );
}

# Testing resource retrieval
{
    my $res = smeagol_request( 'GET', "$server/resource/2" );
    ok( $res->is_success, "resource retrieval status" );
    my $r = Resource->from_xml( $res->content );
    ok( defined $r, "resource retrieval $res->content" );
}

# Testing resource removal
{
    my $res = smeagol_request( 'DELETE', "$server/resource/2" );
    ok( $res->is_success, $res->content );

    $res = smeagol_request( 'DELETE', "$server/resource/1" );
    ok( $res->code == 404, "non-existent resource removal $res->content" );
}

END {
    kill 3, $pid;

    #DataStore->clean();
}
