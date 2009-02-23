#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use Carp;
use Data::Dumper;
use Data::Compare;

BEGIN {

    # Purge old test data before testing anything
    #use_ok("DataStore");
    #DataStore->clean();
    #
    # FIXME: Purge the hard way until DataStore does it better
    #
    unlink glob "/tmp/smeagol_datastore/*";

    use_ok($_) for qw(Server Resource Agenda Booking DateTime);
}

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

# Auxiliary routine to generate smeagol absolute URLs
sub smeagol_url {
    my $suffix = shift;
    return $server . $suffix;
}

# Testing retrieve empty resource list
{
    my $res = smeagol_request( 'GET', "$server/resources" );
    ok( $res->is_success,
        'resource list retrieval status ' . Dumper( $res->code ) );

    ok( $res->content
            =~ m|<\?xml version="1.0" encoding="UTF-8"\?><\?xml-stylesheet href="/css/smeagol.css" type="text/css"\?><resources xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="/resources"></resources>|,
        "resource list content " . Dumper( $res->content )
    );
}

# Build a sample resource to be used in tests
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

# Testing resource creation via XML
{
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml() );
    ok( $res->code == 201,
        "resource creation status " . Dumper( $res->code ) );

    my $xmltree = XMLin( $res->content );

    ok( $xmltree->{description} eq $resource->description && $xmltree->{granularity} eq $resource->granularity,
        "resource creation content " . Dumper( $res->content ) );

}

# Testing list_id with non-empty DataStore
{

    # Count number of resources before test
    my @ids             = DataStore->list_id;
    my $id_count_before = @ids;

    # Create several resources
    my $quants = 3;
    for ( my $i = 0; $i < $quants; $i++ ) {
        my $res = smeagol_request( 'POST', smeagol_url('/resource'),
            $resource->to_xml() );
    }

    # Count number of  after test
    @ids = DataStore->list_id;
    my $id_count_after = @ids;

    ok( $id_count_after == $id_count_before + $quants,
        'list_id with non-empty datastore' );
}

# Testing resource retrieval and removal
{

    # first, we create a new resource
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml() );
    my $xmltree = XMLin( $res->content );

    # retrieve the resource just created
    $res = smeagol_request( 'GET', smeagol_url( $xmltree->{'xlink:href'} ) );
    ok( $res->code == 200,
        "resource $xmltree->{'xlink:href'} retrieval, code "
            . Dumper( $res->code )
    );

    my $r = Resource->from_xml( $res->content, 1000 );
    ok( defined $r, "resource retrieval content " . Dumper( $res->content ) );

    # retrieve non-existent Resource
    $res = smeagol_request( 'GET', smeagol_url('/resource/666') );
    ok( $res->code == 404,
        "non-existent resource retrieval status " . Dumper( $res->code ) );

    # delete the resource just created
    $res = smeagol_request( 'DELETE',
        smeagol_url( $xmltree->{'xlink:href'} ) );
    ok( $res->code == 200, "resource removal $xmltree->{'xlink:href'}" );

    # try to retrieve the deleted resource
    $res = smeagol_request( 'GET', smeagol_url( $xmltree->{'xlink:href'} ) );
    ok( $res->code == 404,
        "retrieval of $xmltree->{'xlink:href'} deleted resource "
            . Dumper( $res->code )
    );
}

# Testing resource update
{

    # first, create a new resource
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml() );

    ok( $res->code == '201',
        'resource creation status ' . Dumper( $res->code ) );
    my $xmltree = XMLin( $res->content );
    my $r       = Resource->from_xml( $res->content, 1000 );

    # modify description
    my $nova_desc = 'He canviat la descripcio';
    $r->description($nova_desc);

    # update resource

    $res = smeagol_request( 'POST', smeagol_url( $xmltree->{'xlink:href'} ),
        $resource->to_xml );

    ok( $res->code == 200,
        "resource $xmltree->{'xlink:href'} update code: "
            . Dumper( $res->code )
    );

}

# Testing list bookings
{
    # first, create a new resource
    my $res = smeagol_request( 'POST', smeagol_url('/resource'), $resource->to_xml() );

    ok( $res->code == '201', 'resource creation status ' . Dumper($res->code));

    my $xmltree = XMLin($res->content);

    print Dumper($xmltree->{agenda}->{'xlink:href'});

    $res = smeagol_request( 'GET', smeagol_url( $xmltree->{agenda}->{'xlink:href'} ) );

    ok( $res->code == 200, "list bookings ". $xmltree->{agenda}->{'xlink:href'} ." status " . Dumper($res->code) );

    #carp Dumper($res->content);

    #my $ag = Agenda->from_xml($res->content);

    #ok( defined $ag , "list bookings content " . Dumper($ag));
}

END {
    kill 3, $pid;
}
