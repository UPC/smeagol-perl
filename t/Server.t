#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 83;
use DateTime;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use Carp;
use Data::Dumper;
use Data::Compare;
use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;

BEGIN {
    use_ok($_) for qw(
        Smeagol::Server
        Smeagol::Resource
        Smeagol::Agenda
        Smeagol::Booking
        Smeagol::TagSet
        Smeagol::Tag
        Smeagol::DataStore
    );
}

my $server_port = 8000;
my $server      = "http://localhost:$server_port";

my $pid = Smeagol::Server->new($server_port)->background();

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

    like(
        $res->content,
        qr|<\?xml version="1.0" encoding="UTF-8"\?>\n<\?xml-stylesheet type="application/xml" href="/xsl/resources.xsl"\?>\n<resources xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="/resources"/>|,
        "resource list content"
    );
}

# Build a sample resource to be used in tests
my $b1 = Smeagol::Booking->new(
    "b1",
    DateTime->new(
        year   => 2008,
        month  => 4,
        day    => 14,
        hour   => 10,
        minute => 0,
        second => 0
    ),
    DateTime->new(
        year   => 2008,
        month  => 4,
        day    => 14,
        hour   => 10,
        minute => 59,
        second => 0
    ),
    "info b1",
);
my $b2 = Smeagol::Booking->new(
    "b2",
    DateTime->new(
        year   => 2008,
        month  => 4,
        day    => 14,
        hour   => 11,
        minute => 0,
        second => 0
    ),
    DateTime->new(
        year   => 2008,
        month  => 4,
        day    => 14,
        hour   => 11,
        minute => 59,
        second => 0
    ),
    "info b2",
);

my $ag = Smeagol::Agenda->new();
$ag->append($b1);
$ag->append($b2);
my $resource  = Smeagol::Resource->new( 'desc 2 2', $ag,   'resource info' );
my $resource2 = Smeagol::Resource->new( 'desc 2 2', undef, 'resource info' );

# Testing resource creation via XML
{
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml() );

    ok( $res->code == 201,
        "resource creation status " . Dumper( $res->code ) );

    my $xmltree = XMLin( $res->content );

    ok( $xmltree->{description} eq $resource->description
            && $xmltree->{info} eq $resource->info,
        "resource creation content " . Dumper( $res->content )
    );

}

# Testing list_id with non-empty DataStore
{

    # Count number of resources before test
    my @ids             = Smeagol::DataStore->list_id;
    my $id_count_before = @ids;

    # Create several resources
    my $quants = 3;
    for ( my $i = 0; $i < $quants; $i++ ) {
        my $res = smeagol_request( 'POST', smeagol_url('/resource'),
            $resource->to_xml() );
    }

    # Count number of  after test
    @ids = Smeagol::DataStore->list_id;
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

    my $r = Smeagol::Resource->from_xml( $res->content, 1000 );
    ok( defined $r, "resource retrieval content " . Dumper( $res->content ) );

    # retrieve non-existent Resource
    $res = smeagol_request( 'GET', smeagol_url('/resource/-666') );
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
    my $r = Smeagol::Resource->from_xml( $res->content, 1000 );

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
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml() );

    ok( $res->code == '201',
        'resource creation status ' . Dumper( $res->code ) );

    my $xmltree = XMLin( $res->content );

    $res = smeagol_request( 'GET',
        smeagol_url( $xmltree->{agenda}->{'xlink:href'} ) );

    ok( $res->code == 200,
        "list bookings "
            . $xmltree->{agenda}->{'xlink:href'}
            . " status "
            . Dumper( $res->code )
    );

    my $ag = Smeagol::Agenda->from_xml( $res->content );

    ok( defined $ag, "list bookings content " . Dumper($ag) );
}

#Testing create booking
{

    # first, create a new resource without agenda, therefore neither bookings
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource2->to_xml() );

    ok( $res->code == '201',
        'resource creation status ' . Dumper( $res->code ) );

    my $xmltree      = XMLin( $res->content );
    my $resource_url = $xmltree->{'xlink:href'};

    $res = smeagol_request( 'POST', smeagol_url("$resource_url/booking"),
        $b1->to_xml() );
    ok( $res->code == '201'
            && Smeagol::Booking->from_xml( $res->content, $b1->id ) == $b1,
        'created booking ' . $res->code
    );

    $res = smeagol_request( 'POST', smeagol_url("$resource_url/booking"),
        $b2->to_xml() );
    ok( $res->code == '201'
            && Smeagol::Booking->from_xml( $res->content, $b2->id ) == $b2,
        'created booking ' . $res->code
    );

    $res = smeagol_request( 'POST', smeagol_url("$resource_url/booking"),
        $b2->to_xml() );
    ok( $res->code == '409',
        'update overlapping booking status ' . $res->code );

    my $ag = Smeagol::Agenda->from_xml( $res->content );

    ok( $ag->size == 1 && ( $ag->elements )[0] == $b2,
        'update overlapping booking content: ' . Dumper( $res->content ) );

}

#Testing retrieve and remove bookings
{

    # first, create a new resource without bookings
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource2->to_xml() );

    ok( $res->code == '201',
        'resource creation status ' . Dumper( $res->code ) );

    my $xmltree      = XMLin( $res->content );
    my $resource_url = $xmltree->{'xlink:href'};

    #and try to retrieve non-existent booking
    $res = smeagol_request( 'GET',
        smeagol_url( $resource_url . '/booking/1' ) );
    ok( $res->code == '404',
        'not retrieved booking because there isn t agenda' );

    # second, add one booking
    $res = smeagol_request( 'POST', smeagol_url( $resource_url . '/booking' ),
        $b1->to_xml() );

    ok( $res->code == '201'
            && Smeagol::Booking->from_xml( $res->content, 1000 ) == $b1,
        'created booking status: ' . Dumper( $res->code )
    );

    $xmltree = XMLin( $res->content );
    my $booking_url = $xmltree->{'xlink:href'};

    #third, retrieve it, remove it, etc
    $res = smeagol_request( 'GET', smeagol_url($booking_url) );
    ok( Smeagol::Booking->from_xml( $res->content, 1000 ) == $b1,
        'retrieved booking' );

    $res = smeagol_request( 'GET',
        smeagol_url( $resource_url . '/booking/1000' ) );
    ok( $res->code == '404', 'not retrieved booking, booking not existent' );

    $res = smeagol_request( 'GET', smeagol_url('/resource/1000/booking/1') );
    ok( $res->code == '404', 'not retrieved booking, resource not existent' );

    $res = smeagol_request( 'POST', smeagol_url( $resource_url . '/booking' ),
        $b2->to_xml() );
    ok( $res->code == '201'
            && Smeagol::Booking->from_xml( $res->content, 1000 ) == $b2,
        'created booking ' . $res->code
    );

    $xmltree     = XMLin( $res->content );
    $booking_url = $xmltree->{'xlink:href'};

    $res = smeagol_request( 'GET', smeagol_url($booking_url) );
    ok( $res->code == 200,
        'retrieve booking status ' . Dumper( $res->code ) );
    ok( Smeagol::Booking->from_xml( $res->content, 1000 ) == $b2,
        'retrieved booking content' );

    $res = smeagol_request( 'DELETE',
        smeagol_url('/resource/1000/booking/1') );
    ok( $res->code == '404',
        'not deleted booking, resource not existent ' . $res->code );

    $res = smeagol_request( 'DELETE', smeagol_url($booking_url) );
    ok( $res->code == '200', 'deleted booking ' . $res->code );

    $res = smeagol_request( 'GET', smeagol_url($booking_url) );
    ok( $res->code == '404',
        'not retrieved booking, booking not existent ' . $res->code );

    $res = smeagol_request( 'DELETE', smeagol_url($booking_url) );
    ok( $res->code == '404',
        'not deleted booking, booking not existent ' . $res->code );

}

# Testing update booking
{
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml );

    ok( $res->code == 201,
        'created resource for booking_update tests: ' . Dumper( $res->code )
    );

    my $xmltree      = XMLin( $res->content );
    my $resource_url = $xmltree->{'xlink:href'};

    $res = smeagol_request( 'GET',
        smeagol_url( $resource_url . '/bookings' ) );

    ok( $res->code == 200,
        'retrieve bookings list: ' . Dumper( $res->code ) );

    my $ag = Smeagol::Agenda->from_xml( $res->content );

    ok( $ag->size == 2, 'agenda size: ' . Dumper( $ag->size ) );

    my ( $booking1, $booking2 ) = $ag->elements;

    # update first booking with non-existent resource #1000
    $res
        = smeagol_request( 'POST',
        smeagol_url( '/resource/1000/booking/' . $booking1->id ),
        $booking1->to_xml );
    ok( $res->code == 404,
        'trying to update booking for non-existent resource: '
            . Dumper( $res->code )
    );

    # update with existent resource, non-existent booking #2222
    $res
        = smeagol_request( 'POST',
        smeagol_url( $resource_url . '/booking/2222' ),
        $booking1->to_xml );
    ok( $res->code == 404,
        'trying to update non-existent booking: ' . Dumper( $res->code ) );

    # existent resource, existent booking, non-valid new booking
    $res = smeagol_request(
        'POST',
        smeagol_url( $resource_url . '/booking/' . $booking1->id ),
        '<booking>I am not a valid booking :-P</booking>'
    );

    ok( $res->code == 400,
        'trying to update with invalid new booking: ' . Dumper( $res->code )
    );

    # new booking producing overlaps with both existent bookings:
    #    booking1: 10:00 - 10:59
    #    booking2: 11:00 - 11:59
    # new_booking: 10:30 - 11:30  (overlaps booking1, booking2)
    my $new_booking = Smeagol::Booking->new(
        "new booking",
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 10,
            minute => 30,
            second => 0
        ),
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 11,
            minute => 30,
            second => 0
        ),
        "new booking info",
    );

    $res
        = smeagol_request( 'POST',
        smeagol_url( $resource_url . '/booking/' . $booking1->id ),
        $new_booking->to_xml );

    ok( $res->code == 409,
        'producing overlappings when updating booking '
            . $resource_url
            . '/booking/'
            . $booking1->id . ': '
            . Dumper( $res->content )
    );

    # update booking, no overlapping
    my $new_booking2 = Smeagol::Booking->new(
        "new booking 2",
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 12,
            minute => 0,
            second => 0
        ),
        DateTime->new(
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 12,
            minute => 59,
            second => 0
        ),
        "new booking 2 info",
    );

    $res
        = smeagol_request( 'POST',
        smeagol_url( $resource_url . '/booking/' . $booking2->id ),
        $new_booking2->to_xml );

    ok( $res->code == 200,
        "update booking $resource_url/booking/"
            . $booking1->id
            . ' status: '
            . Dumper( $res->code )
    );

    my $result = Smeagol::Booking->from_xml( $res->content, $booking2->id );

    ok( $result == $new_booking2 && ( $result->info eq $new_booking2->info ),
        'update booking content: ' . Dumper( $result->to_xml )
    );
}

# Testing iCalendar
{
    my %dtstart = ( year => 2008, month => 4, day => 14, hour => 17 );
    my %dtend   = ( year => 2008, month => 4, day => 14, hour => 18 );

    my $entry = Data::ICal::Entry::Event->new;
    $entry->add_properties(
        summary => "description ical",
        dtstart => Date::ICal->new(%dtstart)->ical,
        dtend   => Date::ICal->new(%dtend)->ical,
    );
    my $calendar = Data::ICal->new;
    $calendar->add_entry($entry);

    my $booking = Smeagol::Booking->new(
        "description ical",
        DateTime->new(%dtstart),
        DateTime->new(%dtend),
    );
    isa_ok( $booking, "Smeagol::Booking" );

    my $agenda = Smeagol::Agenda->new();
    isa_ok( $agenda, "Smeagol::Agenda" );

    $agenda->append($booking);
    my $resource = Smeagol::Resource->new( 'desc ical', $agenda );
    isa_ok( $resource, "Smeagol::Resource" );

    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource->to_xml() );
    ok( $res->code == 201, "resource creation (ical)" );

    my $xmltree = XMLin( $res->content );
    my $xlink   = $xmltree->{agenda}{booking}{"xlink:href"};

    $res = smeagol_request( 'GET', smeagol_url("$xlink/ical") );
    is( $res->code, 200, "booking retrieved (ical)" );

    my @expected = sort grep { !/^(?:PRODID)/ }
        split /\n/, $calendar->as_string;

    my @got = sort grep { !/^(?:PRODID)/ }
        split /\n/, $res->content;

    is_deeply( \@got, \@expected, "looks like an vcalendar" );

    my %dtstart2 = ( year => 2008, month => 4, day => 15, hour => 17 );
    my %dtend2   = ( year => 2008, month => 4, day => 15, hour => 18 );

    my $entry2 = Data::ICal::Entry::Event->new;
    $entry2->add_properties(
        summary => "description ical 2",
        dtstart => Date::ICal->new(%dtstart2)->ical,
        dtend   => Date::ICal->new(%dtend2)->ical,
    );
    $calendar->add_entry($entry2);

    my $booking2 = Smeagol::Booking->new(
        "description ical 2",
        DateTime->new(%dtstart2),
        DateTime->new(%dtend2),
    );
    isa_ok( $booking2, "Smeagol::Booking" );

    my $resourceUrl = $xmltree->{'xlink:href'};
    $res = smeagol_request( 'POST', smeagol_url("$resourceUrl/booking"),
        $booking2->to_xml() );
    ok( $res->code == 201, "booking2 added (ical)" );

    $res
        = smeagol_request( 'GET', smeagol_url("$resourceUrl/bookings/ical") );
    is( $res->code, 200, "resource bookings retrieved (ical)" );

    @expected = sort grep { !/^(?:PRODID)/ }
        split /\n/, $calendar->as_string;

    @got = sort grep { !/^(?:PRODID)/ }
        split /\n/, $res->content;

    is_deeply( \@got, \@expected, "looks like an vcalendar" );
}

my ( $tg, $tg1, $tg2 );
my @valTg
    = ( "campus:nord", "campus nord", "aula", "campus=nord", "projector" );
my $tgS;

#Testing create tag
{

    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource2->to_xml() );
    ok( $res->code == '201', 'resource creation status ' . $res->code );

    $tg = Smeagol::Tag->new("aula");
    ok( defined $tg && $tg->value eq "aula", 'tag created' );

    my $xmltree     = XMLin( $res->content );
    my $resourceUrl = $xmltree->{'xlink:href'};

    $res = smeagol_request( 'POST', smeagol_url("$resourceUrl/tag"),
        $tg->toXML() );
    ok( $res->code == '201' && Smeagol::Tag->from_xml( $res->content ) == $tg,
        'tag in resource'
    );

    $tg = Smeagol::Tag->new("campus:nord");
    ok( defined $tg && $tg->value eq "campus:nord", 'tag created' );

    $res = smeagol_request( 'POST', smeagol_url("$resourceUrl/tag"),
        $tg->toXML() );
    ok( $res->code == '201' && Smeagol::Tag->from_xml( $res->content ) == $tg,
        'tag in resource'
    );

    $tg = Smeagol::Tag->new("projector");
    ok( defined $tg && $tg->value eq "projector", 'tag created' );

    $res = smeagol_request( 'POST', smeagol_url("$resourceUrl/tag"),
        $tg->toXML() );
    ok( $res->code == '201' && Smeagol::Tag->from_xml( $res->content ) == $tg,
        'tag in resource'
    );

    $res = smeagol_request(
        'POST',
        smeagol_url("$resourceUrl/tag"),
        "<tag>campus nord</tag>"
    );
    ok( $res->code == '400', 'tag not created, bad request' );

    $res = smeagol_request( 'POST', smeagol_url("/resource/-222/tag"),
        $tg->toXML() );
    ok( $res->code == '404', 'tag not created, resource not found' );

}

#Retrieving and deleting tags from a resource
{
    my $res = smeagol_request( 'POST', smeagol_url('/resource'),
        $resource2->to_xml() );
    ok( $res->code == '201', 'resource creation status ' . $res->code );

    my $xmltree     = XMLin( $res->content );
    my $resourceUrl = $xmltree->{'xlink:href'};

    $res = smeagol_request( 'GET', smeagol_url( $resourceUrl . '/tags' ) );
    $tgS = Smeagol::TagSet->from_xml( $res->content );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );
    ok( $tgS->size == 0,  'resource with 0 tags' );

    $tg = Smeagol::Tag->new( $valTg[0] );
    ok( defined $tg && $tg->value eq $valTg[0], 'tag created' );

    $tg2 = Smeagol::Tag->new( $valTg[2] );
    ok( defined $tg2 && $tg2->value eq $valTg[2], 'tag created' );

    $res = smeagol_request( 'POST', smeagol_url("$resourceUrl/tag"),
        $tg->toXML() );
    ok( $res->code == '201' && Smeagol::Tag->from_xml( $res->content ) == $tg,
        'tag in resource'
    );

    $res = smeagol_request( 'GET', smeagol_url( $resourceUrl . '/tags' ) );
    $tgS = Smeagol::TagSet->from_xml( $res->content );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );
    ok( $tgS->size == 1,  'resource with 1 tag' );

    $res = smeagol_request( 'POST', smeagol_url("$resourceUrl/tag"),
        $tg2->toXML() );
    ok( $res->code == '201'
            && Smeagol::Tag->from_xml( $res->content ) == $tg2,
        'tag in resource'
    );

    $res = smeagol_request( 'GET', smeagol_url( $resourceUrl . '/tags' ) );
    $tgS = Smeagol::TagSet->from_xml( $res->content );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );
    ok( $tgS->size == 2,  'resource with 2 tag' );

    $res = smeagol_request( 'DELETE',
        smeagol_url( "$resourceUrl/tag/" . $tg2->value ) );
    ok( $res->is_success, 'tag deleting status ' . $res->code );

    $res = smeagol_request( 'GET', smeagol_url( $resourceUrl . '/tags' ) );
    my $tgS = Smeagol::TagSet->from_xml( $res->content );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );
    ok( $tgS->size == 1,  'resource with 1 tag' );

    $res = smeagol_request( 'DELETE',
        smeagol_url( "/resource/-111/tag/" . $tg2->value ) );
    ok( $res->code == '404', 'deleting tag not found, status ' . $res->code );

}

END {
    kill 3, $pid;
    Smeagol::DataStore->clean();
}
