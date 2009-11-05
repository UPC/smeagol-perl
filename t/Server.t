#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 93;
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
use HTTP::Status qw(:constants);

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

my $serverPort = 8000;
my $server     = "http://localhost:$serverPort";

my $pid = Smeagol::Server->new($serverPort)->background();

# Auxiliary routine to encapsulate server requests
sub smeagolRequest {
    my ( $method, $url, $xml ) = @_;

    my $req = HTTP::Request->new( $method => $url );

    $req->content_type('text/xml');
    $req->content($xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res;
}

# Auxiliary routine to generate smeagol absolute URLs
sub smeagolURL {
    my $suffix = shift;
    return $server . $suffix;
}

# Auxiliary routine to compare two Perl hashes, ignoring XLink-related keys
sub smeagolCompare {
    my ( $got, $expected ) = @_;

    return Compare( $got, $expected,
        { ignore_hash_keys => [qw(xmlns:xlink xlink:type xlink:href)] } );
}

# Testing retrieve empty resource list
{
    my $res = smeagolRequest( 'GET', "$server/resources" );
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
    my $res
        = smeagolRequest( 'POST', smeagolURL('/resource'), $resource->toXML );

    ok( $res->code == HTTP_CREATED,
        "resource creation status " . Dumper( $res->code ) );

    my $xmlTree = XMLin( $res->content );

    ok( $xmlTree->{description} eq $resource->description
            && $xmlTree->{info} eq $resource->info,
        "resource creation content " . Dumper( $res->content )
    );
}

# Testing getIDList with non-empty DataStore
{

    # Count number of resources before test
    my @ids           = Smeagol::DataStore->getIDList;
    my $idCountBefore = @ids;

    # Create several resources
    my $quants = 3;
    for ( my $i = 0; $i < $quants; $i++ ) {
        my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
            $resource->toXML() );
    }

    # Count number of  after test
    @ids = Smeagol::DataStore->getIDList;
    my $idCountAfter = @ids;

    ok( $idCountAfter == $idCountBefore + $quants,
        'getIDList with non-empty datastore'
    );
}

# Testing resource retrieval and removal
{

    # first, we create a new resource
    my $res
        = smeagolRequest( 'POST', smeagolURL('/resource'), $resource->toXML );
    my $xmlTreePOST = XMLin( $res->content );

    # retrieve the resource just created
    $res
        = smeagolRequest( 'GET', smeagolURL( $xmlTreePOST->{'xlink:href'} ) );
    ok( $res->code == HTTP_OK,
        "resource $xmlTreePOST->{'xlink:href'} retrieval, status "
            . Dumper( $res->code )
    );

    my $xmlTreeGET = XMLin( $res->content );
    is_deeply( $xmlTreePOST, $xmlTreeGET, 'ok' );

    # retrieve non-existent Resource
    $res = smeagolRequest( 'GET', smeagolURL('/resource/-666') );
    ok( $res->code == HTTP_NOT_FOUND,
        "non-existent resource retrieval status " . Dumper( $res->code ) );

    # delete the resource just created
    $res = smeagolRequest( 'DELETE',
        smeagolURL( $xmlTreeGET->{'xlink:href'} ) );
    ok( $res->code == HTTP_OK,
        "resource removal $xmlTreeGET->{'xlink:href'}" );

    # try to retrieve the deleted resource
    $res = smeagolRequest( 'GET', smeagolURL( $xmlTreeGET->{'xlink:href'} ) );
    ok( $res->code == HTTP_NOT_FOUND,
        "retrieval of $xmlTreeGET->{'xlink:href'} deleted resource "
            . Dumper( $res->code )
    );
}

# Testing resource update
{

    # first, create a new resource
    my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource->toXML() );

    ok( $res->code == HTTP_CREATED,
        'resource creation status ' . Dumper( $res->code ) );
    my $xmlTree = XMLin( $res->content );

    # modify description
    my $novaDesc = 'He canviat la descripcio';
    $resource->description($novaDesc);

    # update resource
    $res = smeagolRequest( 'POST', smeagolURL( $xmlTree->{'xlink:href'} ),
        $resource->toXML );
    my $xmlTreeUP = XMLin( $res->content );

    ok( $res->code == HTTP_OK,
        "resource $xmlTree->{'xlink:href'} update code: "
            . Dumper( $res->code )
    );
    ok( $xmlTree->{description} ne $xmlTreeUP->{description},
        'description changed ok' );
    $xmlTree->{description} = $xmlTreeUP->{description};
    is_deeply( $xmlTree, $xmlTreeUP, 'rest of information not changed' );

}

# Testing list bookings
{

    # first, create a new resource
    my $res1 = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource->toXML() );

    ok( $res1->code == HTTP_CREATED,
        'resource creation status ' . Dumper( $res1->code ) );

    my $xmlTree = XMLin( $res1->content );

    # retrieve resource we've just created
    my $res2 = smeagolRequest( 'GET',
        smeagolURL( $xmlTree->{agenda}->{'xlink:href'} ) );

    ok( $res2->code == HTTP_OK,
        "list bookings "
            . $xmlTree->{agenda}->{'xlink:href'}
            . " status "
            . Dumper( $res2->code )
    );
    ok( smeagolCompare( XMLin( $res2->content ), $xmlTree->{agenda} ),
        'list bookings ok' );
}

#Testing create booking
{

    # first, create a new resource without agenda, therefore neither bookings
    my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource2->toXML() );

    ok( $res->code == HTTP_CREATED,
        'resource creation status ' . Dumper( $res->code ) );

    my $xmlTree     = XMLin( $res->content );
    my $resourceURL = $xmlTree->{'xlink:href'};

    # add booking b1 to the agenda
    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/booking"),
        $b1->toXML() );
    ok( $res->code == HTTP_CREATED, 'booking creation status' );

    ok( smeagolCompare( XMLin( $res->content ), XMLin( $b1->toXML ) ),
        'booking creation content' );

    # add booking b2 to the agenda
    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/booking"),
        $b2->toXML() );
    ok( $res->code == HTTP_CREATED,
        'booking creation status: ' . $res->code );
    ok( smeagolCompare( XMLin( $res->content ), XMLin( $b2->toXML ) ),
        'booking creation content' );

    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/booking"),
        $b2->toXML() );
    ok( $res->code == HTTP_CONFLICT,
        'update overlapping booking status ' . $res->code );

    my $ag = Smeagol::Agenda->new();
    $ag->append($b2);

    ok( smeagolCompare( XMLin( $res->content ), XMLin( $ag->toXML ) ),
        'update overlapping booking content' );
}

#Testing retrieve and remove bookings
{

    # first, create a new resource without bookings
    my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource2->toXML() );

    ok( $res->code == HTTP_CREATED,
        'resource creation status ' . Dumper( $res->code ) );

    my $xmlTree     = XMLin( $res->content );
    my $resourceURL = $xmlTree->{'xlink:href'};

    #and try to retrieve non-existent booking
    $res = smeagolRequest( 'GET', smeagolURL( $resourceURL . '/booking/1' ) );
    ok( $res->code == HTTP_NOT_FOUND,
        'not retrieved booking because there isn t agenda' );

    # second, add one booking
    $res = smeagolRequest( 'POST', smeagolURL( $resourceURL . '/booking' ),
        $b1->toXML() );

    ok( $res->code == HTTP_CREATED, 'booking creation status' );
    ok( smeagolCompare( XMLin( $res->content ), XMLin( $b1->toXML ) ),
        'booking creation status' );

    $xmlTree = XMLin( $res->content );
    my $bookingURL = $xmlTree->{'xlink:href'};

    #third, retrieve it, remove it, etc
    $res = smeagolRequest( 'GET', smeagolURL($bookingURL) );
    ok( smeagolCompare( XMLin( $res->content ), XMLin( $b1->toXML ) ),
        'retrieved booking' );

    $res = smeagolRequest( 'GET',
        smeagolURL( $resourceURL . '/booking/1000' ) );
    ok( $res->code == HTTP_NOT_FOUND,
        'not retrieved booking, booking not existent' );

    $res = smeagolRequest( 'GET', smeagolURL('/resource/1000/booking/1') );
    ok( $res->code == HTTP_NOT_FOUND,
        'not retrieved booking, resource not existent' );

    $res = smeagolRequest( 'POST', smeagolURL( $resourceURL . '/booking' ),
        $b2->toXML() );
    ok( smeagolCompare( XMLin( $res->content ), XMLin( $b2->toXML ) ),
        'created booking ' . $res->code );

    $xmlTree    = XMLin( $res->content );
    $bookingURL = $xmlTree->{'xlink:href'};

    $res = smeagolRequest( 'GET', smeagolURL($bookingURL) );
    ok( $res->code == HTTP_OK,
        'retrieve booking status ' . Dumper( $res->code ) );
    ok( smeagolCompare( XMLin( $res->content ), XMLin( $b2->toXML ) ),
        'retrieve booking content' );

    $res = smeagolRequest( 'DELETE', smeagolURL('/resource/1000/booking/1') );
    ok( $res->code == HTTP_NOT_FOUND,
        'not deleted booking, resource not existent ' . $res->code );

    $res = smeagolRequest( 'DELETE', smeagolURL($bookingURL) );
    ok( $res->code == HTTP_OK, 'deleted booking ' . $res->code );

    $res = smeagolRequest( 'GET', smeagolURL($bookingURL) );
    ok( $res->code == HTTP_NOT_FOUND,
        'not retrieved booking, booking not existent ' . $res->code );

    $res = smeagolRequest( 'DELETE', smeagolURL($bookingURL) );
    ok( $res->code == HTTP_NOT_FOUND,
        'not deleted booking, booking not existent ' . $res->code );

}

# Testing update booking
{
    my $res
        = smeagolRequest( 'POST', smeagolURL('/resource'), $resource->toXML );

    ok( $res->code == HTTP_CREATED,
        'created resource for booking_update tests: ' . Dumper( $res->code )
    );

    my $xmlTree     = XMLin( $res->content );
    my $resourceURL = $xmlTree->{'xlink:href'};

    $res = smeagolRequest( 'GET', smeagolURL( $resourceURL . '/bookings' ) );

    ok( $res->code == HTTP_OK,
        'retrieve bookings list: ' . Dumper( $res->code ) );

    my $expected = XMLin( $resource->agenda->toXML );
    my $got      = XMLin( $res->content );

    ok( smeagolCompare( XMLin( $res->content ), $expected ) );

    my ( $booking1, $booking2 ) = $resource->agenda->elements;

    # update first booking with non-existent resource #1000
    $res
        = smeagolRequest( 'POST',
        smeagolURL( '/resource/1000/booking/' . $booking1->id ),
        $booking1->toXML );
    ok( $res->code == HTTP_NOT_FOUND,
        'trying to update booking for non-existent resource: '
            . Dumper( $res->code )
    );

    # update with existent resource, non-existent booking #2222
    $res
        = smeagolRequest( 'POST',
        smeagolURL( $resourceURL . '/booking/2222' ),
        $booking1->toXML );
    ok( $res->code == HTTP_NOT_FOUND,
        'trying to update non-existent booking: ' . Dumper( $res->code ) );

    # existent resource, existent booking, non-valid new booking
    $res = smeagolRequest(
        'POST',
        smeagolURL( $resourceURL . '/booking/' . $booking1->id ),
        '<booking>I am not a valid booking :-P</booking>'
    );

    ok( $res->code == HTTP_BAD_REQUEST,
        'trying to update with invalid new booking: ' . Dumper( $res->code )
    );

    # new booking producing overlaps with both existent bookings:
    #    booking1: 10:00 - 10:59
    #    booking2: 11:00 - 11:59
    #  newBooking: 10:30 - 11:30  (overlaps booking1, booking2)
    my $newBooking = Smeagol::Booking->new(
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
        = smeagolRequest( 'POST',
        smeagolURL( $resourceURL . '/booking/' . $booking1->id ),
        $newBooking->toXML );

    ok( $res->code == HTTP_CONFLICT,
        'producing overlappings when updating booking '
            . $resourceURL
            . '/booking/'
            . $booking1->id . ': '
            . Dumper( $res->content )
    );

    # update booking, no overlapping
    my $newBooking2 = Smeagol::Booking->new(
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
        = smeagolRequest( 'POST',
        smeagolURL( $resourceURL . '/booking/' . $booking2->id ),
        $newBooking2->toXML );

    ok( $res->code == HTTP_OK,
        "update booking $resourceURL/booking/"
            . $booking1->id
            . ' status: '
            . Dumper( $res->code )
    );

    ok( smeagolCompare(
            XMLin( $res->content ), XMLin( $newBooking2->toXML )
        ),
        'update booking content: ' . Dumper( $res->content )
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

    my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource->toXML() );
    ok( $res->code == HTTP_CREATED, "resource creation (ical)" );

    my $xmlTree = XMLin( $res->content );
    my $xlink   = $xmlTree->{agenda}{booking}{"xlink:href"};

    $res = smeagolRequest( 'GET', smeagolURL("$xlink/ical") );
    is( $res->code, HTTP_OK, "booking retrieved (ical)" );

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

    my $resourceURL = $xmlTree->{'xlink:href'};
    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/booking"),
        $booking2->toXML() );
    ok( $res->code == HTTP_CREATED, "booking2 added (ical)" );

    $res = smeagolRequest( 'GET', smeagolURL("$resourceURL/bookings/ical") );
    is( $res->code, HTTP_OK, "resource bookings retrieved (ical)" );

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

    my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource2->toXML() );
    ok( $res->code == HTTP_CREATED,
        'resource creation status ' . $res->code );

    $tg = Smeagol::Tag->new("aula");
    ok( defined $tg && $tg->value eq "aula", 'tag created' );

    my $xmlTree     = XMLin( $res->content );
    my $resourceURL = $xmlTree->{'xlink:href'};

    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/tag"),
        $tg->toXML() );
    ok( $res->code == HTTP_CREATED, 'tag creation status' );

    ok( smeagolCompare(
            XMLin( $res->content, ContentKey => 'tag' ),
            XMLin( $tg->toXML,    KeepRoot   => 1 )
        ),
        'tag creation content'
    );

    $tg = Smeagol::Tag->new("campus:nord");
    ok( defined $tg && $tg->value eq "campus:nord", 'tag created' );

    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/tag"),
        $tg->toXML() );
    ok( $res->code == HTTP_CREATED, 'tag creation status' );
    ok( smeagolCompare(
            XMLin( $res->content, ContentKey => 'tag' ),
            XMLin( $tg->toXML,    KeepRoot   => 1 )
        ),
        'tag creation status'
    );

    $tg = Smeagol::Tag->new("projector");
    ok( defined $tg && $tg->value eq "projector", 'tag created' );

    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/tag"),
        $tg->toXML() );
    ok( $res->code == HTTP_CREATED, 'tag creation status' );
    ok( smeagolCompare(
            XMLin( $res->content, ContentKey => 'tag' ),
            XMLin( $tg->toXML,    KeepRoot   => 1 )
        ),
        'tag creation content'
    );

    $res = smeagolRequest(
        'POST',
        smeagolURL("$resourceURL/tag"),
        "<tag>campus nord</tag>"
    );
    ok( $res->code == HTTP_BAD_REQUEST, 'tag not created, bad request' );

    $res = smeagolRequest( 'POST', smeagolURL("/resource/-222/tag"),
        $tg->toXML() );
    ok( $res->code == HTTP_NOT_FOUND, 'tag not created, resource not found' );

}

#Retrieving and deleting tags from a resource
{
    my $res = smeagolRequest( 'POST', smeagolURL('/resource'),
        $resource2->toXML() );
    ok( $res->code == HTTP_CREATED,
        'resource creation status ' . $res->code );

    my $xmlTree     = XMLin( $res->content );
    my $resourceURL = $xmlTree->{'xlink:href'};

    $res = smeagolRequest( 'GET', smeagolURL( $resourceURL . '/tags' ) );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );

    ok( smeagolCompare(
            XMLin( $res->content ),
            XMLin( $resource2->tags->toXML )
        ),
        'tag list retrieval content'
    );

    $tg = Smeagol::Tag->new( $valTg[0] );
    ok( defined $tg && $tg->value eq $valTg[0], 'tag created' );

    $tg2 = Smeagol::Tag->new( $valTg[2] );
    ok( defined $tg2 && $tg2->value eq $valTg[2], 'tag created' );

    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/tag"),
        $tg->toXML() );
    ok( $res->code == HTTP_CREATED, 'tag creation status ' . $res->code );
    ok( smeagolCompare(
            XMLin( $res->content, ContentKey => 'tag' ),
            XMLin( $tg->toXML,    KeepRoot   => 1 )
        ),
        'tag creation content'
    );

    $res = smeagolRequest( 'GET', smeagolURL( $resourceURL . '/tags' ) );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );

    my $tagSet = Smeagol::TagSet->new();
    $tagSet->append($tg);
    print Dumper( XMLin( $res->content ), XMLin( $tagSet->toXML ) );
    ok( smeagolCompare( XMLin( $res->content ), XMLin( $tagSet->toXML ) ),
        'tag list retrieval content' );

    $res = smeagolRequest( 'POST', smeagolURL("$resourceURL/tag"),
        $tg2->toXML() );
    ok( $res->code == HTTP_CREATED, 'tag creation status' );
    ok( smeagolCompare(
            XMLin( $res->content, ContentKey => 'tag' ),
            XMLin( $tg2->toXML,   KeepRoot   => 1 )
        ),
        'tag creation content'
    );

    $res = smeagolRequest( 'GET', smeagolURL( $resourceURL . '/tags' ) );
    $tgS = Smeagol::TagSet->newFromXML( $res->content );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );
    ok( $tgS->size == 2,  'resource with 2 tag' );

    $res = smeagolRequest( 'DELETE',
        smeagolURL( "$resourceURL/tag/" . $tg2->value ) );
    ok( $res->is_success, 'tag deleting status ' . $res->code );

    $res = smeagolRequest( 'GET', smeagolURL( $resourceURL . '/tags' ) );
    my $tgS = Smeagol::TagSet->newFromXML( $res->content );
    ok( $res->is_success, 'tag list retrieval status ' . $res->code );
    ok( $tgS->size == 1,  'resource with 1 tag' );

    $res = smeagolRequest( 'DELETE',
        smeagolURL( "/resource/-111/tag/" . $tg2->value ) );
    ok( $res->code == HTTP_NOT_FOUND,
        'deleting tag not found, status ' . $res->code );

}

END {
    kill 3, $pid;
    Smeagol::DataStore->clean();
}
