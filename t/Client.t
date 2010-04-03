#!/usr/bin/perl

use Test::More tests => 84;

use strict;
use warnings;
use Data::Dumper;
use Data::Compare;

use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

BEGIN {
    use_ok($_) for qw(
        Smeagol::Server
        Smeagol::Client
        Smeagol::DataStore
    );
}

# Auxiliary routine to compare two Perl hashes, ignoring XLink-related keys
sub smeagolCompare {
    my ( $got, $expected ) = @_;

    return Compare( $got, $expected,
        { ignore_hash_keys => [qw(xmlns:xlink xlink:type xlink:href)] } );
}

my $serverPort = 8000;
my $server     = "http://localhost:$serverPort";
my $pid        = Smeagol::Server->new($serverPort)->background();

my $client = Smeagol::Client->new();
ok( !defined $client, 'client not created' );

# bad.example.com was failing with DNS hijackers,
# so we converted it into a "bat" ;)
$client = Smeagol::Client->new("http://^^o^^.example.com");
ok( !defined $client, 'client not created, bad DNS record' );

$client = Smeagol::Client->new("://www.example.com");
ok( !defined $client, 'client not created, bad scheme URI' );

$client = Smeagol::Client->new("http://www.example.com");
ok( !defined $client, 'client not created, server not responding' );

$client = Smeagol::Client->new($server);
ok( ref $client eq 'Smeagol::Client', 'client created' );

my @idResources;
my @Resources;
my $idRes;
my $dataRes;
my $idBook;
my $dataBoo;
my @idBookings;
my @Bookings;
my $idAg;
my $idTg;
my @valTg;

my $desc = "description 1";
my $from = {
    year   => 2008,
    month  => 4,
    day    => 14,
    hour   => 17,
    minute => 0,
    second => 0,
};
my $to = {
    year   => 2008,
    month  => 4,
    day    => 14,
    hour   => 19,
    minute => 0,
    second => 0,
};
my $info = "info 1";

my $desc2 = "description 2";
my $from2 = {
    year   => 2008,
    month  => 4,
    day    => 15,
    hour   => 19,
    minute => 0,
    second => 0,
};
my $to2 = {
    year   => 2008,
    month  => 4,
    day    => 15,
    hour   => 20,
    minute => 0,
    second => 0,
};
my $info2 = "info 2";

my $desc3 = "description 3";
my $from3 = {
    year   => 2008,
    month  => 4,
    day    => 15,
    hour   => 9,
    minute => 0,
    second => 0,
};
my $to3 = {
    year   => 2008,
    month  => 4,
    day    => 15,
    hour   => 11,
    minute => 0,
    second => 0,
};
my $info3 = "info 3";

my $desc0 = "description 0";
my $from0 = {
    year   => 2008,
    month  => 4,
    day    => 14,
    hour   => 16,
    minute => 0,
    second => 0,
};
my $to0 = {
    year   => 2008,
    month  => 4,
    day    => 14,
    hour   => 17,
    minute => 0,
    second => 0,
};
my $info0 = "info 0";

# Testing retrieve empty resource list
{
    @idResources = $client->listResources();
    ok( @idResources == 0, 'list resources empty' );
}

# Testing resource creation and retrieving not an empty list
{
    push @Resources, $client->createResource( "aula", "info aula" );
    ok( defined $Resources[0], 'created resource ' . $Resources[0]->{id} );

    @idResources = $client->listResources();
    ok( $idResources[0]->{id} eq $Resources[0]->{id},
        'resource ' . $Resources[0]->{id} . ' at list'
    );
    push @Resources,
        $idRes = $client->createResource( "projector", "info projector" );
    ok( defined $Resources[1]->{id},
        'created resource ' . $Resources[1]->{id} );

    @idResources = $client->listResources();
    ok( @idResources == 2, 'list resources 2 element' );

    push @Resources,
        $idRes = $client->createResource( "projector", "info projector" );
    ok( defined $Resources[2], 'created resource ' . $Resources[2]->{id} );

    @idResources = $client->listResources();
    ok( @idResources == 3, 'list resources 3 element' );

    ok( $idResources[0]->{id} eq $Resources[0]->{id},
        'resource ' . $Resources[0]->{id} . ' begin'
    );
    ok( $idResources[1]->{id} eq $Resources[1]->{id},
        'resource ' . $Resources[1]->{id} . ' between'
    );
    ok( $idResources[2]->{id} eq $Resources[2]->{id},
        'resource ' . $Resources[2]->{id} . ' end'
    );
}

#Testing resource updating and getting
{

    # checking updateResource only changes description and info; tags and
    # bookings should remain unmodified. See ticket #171
    my $resource = $client->getResource( $Resources[0]->{id} );
    ok( defined $resource && $resource->{id} eq $Resources[0]->{id},
        'resource retrieval for updateResource tests' );

    # add tag and booking to the resource
    my $idTag = $client->createTag( $resource->{id}, 'dummytag' );
    ok( defined $idTag, 'tag creation for updateResource tests' );

    my $desc = 'dummy booking description';
    my $from = {
        year   => 2010,
        month  => 4,
        day    => 1,
        hour   => 16,
        minute => 0,
        second => 0,
    };
    my $to = {
        year   => 2010,
        month  => 4,
        day    => 1,
        hour   => 17,
        minute => 0,
        second => 0,
    };
    my $info = 'dummy booking for updateResource tests';

    my $booking
        = $client->createBooking( $resource->{id}, $desc, $from, $to, $info );
    ok( defined $booking, 'booking created for updateResource tests' );

    my $oldResource = $client->getResource( $resource->{id} );
    my @oldAgenda   = $client->listBookings( $resource->{id} );
    ok( @oldAgenda, 'retrieving bookings before update' );

    my $NEW_DESC = 'aulaaaaaa';
    my $NEW_INFO = 'info aulaaaaaa';
    $idRes
        = $client->updateResource( $oldResource->{id}, $NEW_DESC, $NEW_INFO );
    ok( $idRes->{id} eq $oldResource->{id},
        'updated resource ' . $oldResource->{id}
    );

    my $newResource = $client->getResource( $idRes->{id} );
    my @newAgenda   = $client->listBookings( $resource->{id} );
    ok( @newAgenda, 'retrieving bookings after update' );

    ok( $newResource->{description} eq $NEW_DESC,
        'description updated successfully'
    );
    ok( $newResource->{info} eq $NEW_INFO, 'info updated successfully' );

    ok( Compare(
            $newResource,
            $oldResource,
            {   ignore_hash_keys =>
                    [qw(xmlns:xlink xlink:type xlink:href description info)]
            }
        ),
        'bookings and tags did not change'
    );

    ok( Compare( @oldAgenda, @newAgenda ), 'agenda contents did not change' );

    @idResources = $client->listResources();
    ok( $idResources[0]->{id} eq $Resources[0]->{id},
        'resource ' . $Resources[0]->{id} . ' at list'
    );

    $idRes = $client->updateResource( $Resources[1]->{id},
        "projector", "info projector" );
    ok( $idRes->{id} eq $Resources[1]->{id},
        'updated resource ' . $Resources[1]->{id}
    );

    $dataRes = $client->getResource( $Resources[1]->{id} );
    ok( $dataRes->{description} eq 'projector'
            && !defined $dataRes->{agenda}
            && $dataRes->{info} eq 'info projector',
        'get resource ' . $Resources[1]->{id}
    );

}

#Testing deleting resource
{
    @idResources = $client->listResources();
    ok( @idResources == 3, 'list resources not empty' );

    $idRes = $client->delResource( $Resources[0]->{id} );
    ok( $idRes->{id} eq $Resources[0]->{id},
        'deleted resource ' . $Resources[0]->{id}
    );

    @idResources = $client->listResources();
    ok( @idResources == 2, 'list resources not empty' );

    $idRes = $client->delResource( $Resources[2]->{id} );
    ok( $idRes->{id} eq $Resources[2]->{id},
        'deleted resource ' . $Resources[2]->{id}
    );

    @idResources = $client->listResources();
    ok( @idResources == 1, 'list resources not empty' );
    ok( $idResources[0]->{id} eq $Resources[1]->{id},
        'remining resource is ' . $Resources[1]->{id}
    );
}

#Testing retrieve Agenda empty
{
    @idBookings = $client->listBookings( $Resources[1]->{id} );
    ok( @idBookings == 0, 'empty Agenda at ' . $Resources[1]->{id} );
}

#Testing create booking
{
    push @Bookings,
        $client->createBooking( $Resources[1]->{id},
        $desc, $from, $to, $info );
    ok( defined $Bookings[0], 'booking created ' . $Bookings[0]->{id} );

    my @books = $client->listBookings( $Resources[1]->{id} );
    ok( $books[0]->{idR} eq $Resources[1]->{id},
        'list with only one booking' );

    $dataRes = $client->getResource( $Resources[1]->{id} );
    ok( $dataRes->{agenda} eq $client->{url}
            . "/resource/"
            . $Resources[1]->{id}
            . "/bookings",
        "retrieving a resource with agenda"
    );

    push @Bookings,
        $client->createBooking( $Resources[1]->{id},
        $desc2, $from2, $to2, $info2 );
    ok( defined $Bookings[1], 'booking created ' . $Bookings[1]->{id} );

    push @Bookings,
        $client->createBooking( $Resources[1]->{id},
        $desc, $from, $to, $info );
    ok( !exists $Bookings[2], 'booking not created, intersection' );

    push @Bookings,
        $client->createBooking( $Resources[1]->{id},
        $desc3, $from3, $to3, $info3 );
    ok( defined $Bookings[2], 'booking created ' . $Bookings[2]->{id} );

    my $ical1
        = $client->getBookingICal( $Bookings[0]->{idR}, $Bookings[0]->{id} );
    my $ical2 = $client->listBookingsICal( $Resources[1]->{id} );

    my $entry = Data::ICal::Entry::Event->new();
    $entry->add_properties(
        summary => $desc,
        dtstart => Date::ICal->new(
            year   => $from->{year},
            month  => $from->{month},
            day    => $from->{day},
            hour   => $from->{hour},
            minute => $from->{minute},
            second => $from->{second},
            )->ical,
        dtend => Date::ICal->new(
            year   => $to->{year},
            month  => $to->{month},
            day    => $to->{day},
            hour   => $to->{hour},
            minute => $to->{minute},
            second => $to->{second},
            )->ical,
    );
    my $calendar = Data::ICal->new();
    $calendar->add_entry($entry);

    my @ical1 = sort grep { !/^(?:PRODID)/ }
        split /\n/, $ical1;
    my @expected = sort grep { !/^(?:PRODID)/ }
        split /\n/, $calendar->as_string;

    is_deeply( \@ical1, \@expected, "get booking ical" );

    $entry = Data::ICal::Entry::Event->new();
    $entry->add_properties(
        summary => $desc2,
        dtstart => Date::ICal->new(
            year   => $from2->{year},
            month  => $from2->{month},
            day    => $from2->{day},
            hour   => $from2->{hour},
            minute => $from2->{minute},
            second => $from2->{second},
            )->ical,
        dtend => Date::ICal->new(
            year   => $to2->{year},
            month  => $to2->{month},
            day    => $to2->{day},
            hour   => $to2->{hour},
            minute => $to2->{minute},
            second => $to2->{second},
            )->ical,
    );
    $calendar->add_entry($entry);
    $entry = Data::ICal::Entry::Event->new();
    $entry->add_properties(
        summary => $desc3,
        dtstart => Date::ICal->new(
            year   => $from3->{year},
            month  => $from3->{month},
            day    => $from3->{day},
            hour   => $from3->{hour},
            minute => $from3->{minute},
            second => $from3->{second},
            )->ical,
        dtend => Date::ICal->new(
            year   => $to3->{year},
            month  => $to3->{month},
            day    => $to3->{day},
            hour   => $to3->{hour},
            minute => $to3->{minute},
            second => $to3->{second},
            )->ical,
    );
    $calendar->add_entry($entry);

    my @ical2 = sort grep { !/^(?:PRODID)/ }
        split /\n/, $ical2;
    @expected = sort grep { !/^(?:PRODID)/ }
        split /\n/, $calendar->as_string;

    is_deeply( \@ical2, \@expected, "list bookings ical" );
}

#Testing retrieve Agenda not empty
{
    @idBookings = $client->listBookings( $Resources[1]->{id} );
    ok( @idBookings == 3 && $idBookings[2]->{idR} == $Resources[1]->{id},
        'not empty Agenda at ' . $Resources[1]->{id} );

    @idBookings = $client->listBookings( $Resources[0]->{id} );
    ok( !defined $idBookings[0], 'empty Agenda at ' . $Resources[0]->{id} );

}

#Testing retrieve and delete booking
{
    $dataBoo = $client->getBooking( $Bookings[1]->{idR}, $Bookings[1]->{id} );
    ok( $dataBoo->{from}->{year} == 2008
            && $dataBoo->{from}->{month} == 4
            && $dataBoo->{from}->{day} == 15
            && $dataBoo->{from}->{hour} == 19
            && $dataBoo->{from}->{minute} == 0
            && $dataBoo->{from}->{second} == 0
            && $dataBoo->{to}->{year} == 2008
            && $dataBoo->{to}->{month} == 4
            && $dataBoo->{to}->{day} == 15
            && $dataBoo->{to}->{hour} == 20
            && $dataBoo->{to}->{minute} == 0
            && $dataBoo->{to}->{second} == 0,
        'resource '
            . $Bookings[1]->{idR}
            . ' booking '
            . $Bookings[1]->{id}
            . '-> retrieved'
    );

    $dataBoo = $client->getBooking( $Bookings[0]->{idR}, $Bookings[0]->{id} );
    ok( $dataBoo->{from}->{year} == 2008
            && $dataBoo->{from}->{month} == 4
            && $dataBoo->{from}->{day} == 14
            && $dataBoo->{from}->{hour} == 17
            && $dataBoo->{from}->{minute} == 0
            && $dataBoo->{from}->{second} == 0
            && $dataBoo->{to}->{year} == 2008
            && $dataBoo->{to}->{month} == 4
            && $dataBoo->{to}->{day} == 14
            && $dataBoo->{to}->{hour} == 19
            && $dataBoo->{to}->{minute} == 0
            && $dataBoo->{to}->{second} == 0,
        'resource '
            . $Bookings[0]->{idR}
            . ' booking '
            . $Bookings[0]->{id}
            . '-> retrieved'
    );

    $idBook = $client->delBooking( $Bookings[0]->{idR}, $Bookings[0]->{id} );
    ok( $idBook->{id} eq $Bookings[0]->{id},
        'deleted booking ' . $Bookings[0]->{id}
    );

    $dataBoo = $client->getBooking( $Bookings[0]->{idR}, $Bookings[0]->{id} );
    ok( !defined $dataBoo, 'retrieving booking not existent' );

    $idBook = $client->delBooking( $Resources[0]->{idR}, 1 );
    ok( !defined $idBook, 'not deleted booking, resource not existent' );

    $idBook = $client->delBooking( $Resources[1]->{idR}, -100 );
    ok( !defined $idBook, 'not deleted booking, booking not existent' );
}

#Testing retrieve Agenda not empty after deleting
{
    @idBookings = $client->listBookings( $Resources[1]->{id} );
    ok( @idBookings == 2, 'not empty Agenda at ' . $Resources[1]->{id} );
}

#Testing update Booking
{
    $idBook = $client->updateBooking(
        $Bookings[0]->{idR},
        $Bookings[0]->{id},
        $desc, $from, $to
    );
    ok( !defined $idBook, 'not updated booking, not existent resource' );

    $idBook
        = $client->updateBooking( $Resources[2]->{id}, 1, $desc, $from, $to );
    ok( !defined $idBook, 'not updated booking, not existent resource' );

    $idBook = $client->updateBooking( $Resources[1]->{id}, -555, $desc, $from,
        $to );
    ok( !defined $idBook, 'not updated booking, not existent booking' );

    $idBook = $client->updateBooking(
        $Bookings[1]->{idR},
        $Bookings[1]->{id},
        $desc2, $from2, $to2
    );
    ok( defined $idBook, 'updated booking ' . $Bookings[1]->{id} );

    $dataBoo = $client->getBooking( $Bookings[1]->{idR}, $Bookings[1]->{id} );
    ok( $dataBoo->{from}->{year} == $from2->{year}
            && $dataBoo->{from}->{month} == $from2->{month}
            && $dataBoo->{from}->{day} == $from2->{day}
            && $dataBoo->{from}->{hour} == $from2->{hour}
            && $dataBoo->{from}->{minute} == $from2->{minute}
            && $dataBoo->{from}->{second} == $from2->{second}
            && $dataBoo->{to}->{year} == $to2->{year}
            && $dataBoo->{to}->{month} == $to2->{month}
            && $dataBoo->{to}->{day} == $to2->{day}
            && $dataBoo->{to}->{hour} == $to2->{hour}
            && $dataBoo->{to}->{minute} == $to2->{minute}
            && $dataBoo->{to}->{second} == $to2->{second},
        'retrieved booking updated' . $Bookings[1]->{id}
    );

    $idBook = $client->updateBooking(
        $Bookings[2]->{idR},
        $Bookings[2]->{id},
        $desc2, $from2, $to2
    );
    ok( !defined $idBook,
        'not updated booking, intersection '
            . $Bookings[2]->{idR} . ' '
            . $Bookings[2]->{id}
    );

    $idBook = $client->updateBooking(
        $Bookings[2]->{idR},
        $Bookings[2]->{id},
        $desc, $from, $to
    );
    ok( defined $idBook, 'updated booking ' . $idBook->{id} );

    $dataBoo = $client->getBooking( $Bookings[2]->{idR}, $Bookings[2]->{id} );
    ok( $dataBoo->{from}->{year} == $from->{year}
            && $dataBoo->{from}->{month} == $from->{month}
            && $dataBoo->{from}->{day} == $from->{day}
            && $dataBoo->{from}->{hour} == $from->{hour}
            && $dataBoo->{from}->{minute} == $from->{minute}
            && $dataBoo->{from}->{second} == $from->{second}
            && $dataBoo->{to}->{year} == $to->{year}
            && $dataBoo->{to}->{month} == $to->{month}
            && $dataBoo->{to}->{day} == $to->{day}
            && $dataBoo->{to}->{hour} == $to->{hour}
            && $dataBoo->{to}->{minute} == $to->{minute}
            && $dataBoo->{to}->{second} == $to->{second},
        'retrieved booking updated ' . $Bookings[2]->{id}
    );

}

@valTg = (
    "campus nord",     "aula",
    "aula multimedia", "campus:nord-aula:multidemia"
);

#create tag
{
    @Resources = ();

    push @Resources, $client->createResource( "aula", "hora" );
    ok( defined $Resources[0], 'created resource ' . $Resources[0]->{id} );
    $idTg = $client->createTag( $Resources[0]->{id}, $valTg[0] );
    ok( !defined $idTg, 'tag not added' );

    $idTg = $client->createTag( -111, $valTg[1] );
    ok( !defined $idTg, "tag not added, resource doesn't exist" );

    $idTg = $client->createTag( -111, $valTg[0] );
    ok( !defined $idTg, "tag not added, incorrect tag" );

    $idTg = $client->createTag( $Resources[0]->{id}, $valTg[1] );
    ok( defined $idTg && $idTg->{content} eq $valTg[1], 'tag added' );

    $idTg = $client->createTag( $Resources[0]->{id}, $valTg[3] );
    ok( defined $idTg && $idTg->{content} eq $valTg[3], 'tag added' );

    $idTg = $client->createTag( "/resource/-111", "aula" );
    ok( !defined $idTg, 'tag not added' );
}

my @tgS;

#Retrieving and deleting tags from a resource
{
    @Resources = ();

    push @Resources, $client->createResource( "aulaaaaa", "hora" );
    ok( defined $Resources[0], 'created resource ' . $Resources[0]->{id} );

    push @tgS, $client->listTags( $Resources[0]->{id} );
    ok( @tgS == 0, 'list with 0 tags ' . $Resources[0]->{id} );

    $idTg = $client->createTag( $Resources[0]->{id}, $valTg[1] );
    ok( defined $idTg && $idTg->{content} eq $valTg[1],
        'tag added at ' . $Resources[0]->{id}
    );

    @tgS = $client->listTags( $Resources[0]->{id} );
    ok( @tgS == 1, 'list with 1 tags en resource ' . $Resources[0]->{id} );

    $idTg = $client->createTag( $Resources[0]->{id}, $valTg[3] );
    ok( defined $idTg && $idTg->{content} eq $valTg[3],
        'tag added at ' . $Resources[0]->{id}
    );

    @tgS = $client->listTags( $Resources[0]->{id} );
    ok( @tgS == 2, 'list with 2 tags in resource ' . $Resources[0]->{id} );

    $idTg = $client->delTag( $Resources[0]->{id}, $valTg[3] );
    ok( defined $idTg && $idTg->{content} eq $valTg[3],
        'tag deleted at ' . $Resources[0]->{id}
    );

    @tgS = $client->listTags( $Resources[0]->{id} );
    ok( @tgS == 1, 'list with 1 tag in resource ' . $Resources[0]->{id} );
    ok( $tgS[0]->{content} eq $valTg[1],
        'correct remining tag at ' . $Resources[0]->{id} );

    $idTg = $client->delTag( -111, $valTg[1] );
    ok( !defined $idTg, "tag not deleted, resource doesn't exist" );

    $idTg = $client->delTag( $Resources[0]->{id}, $valTg[1] );
    ok( defined $idTg && $idTg->{content} eq $valTg[1],
        'tag deleted at ' . $Resources[0]->{id}
    );

    @tgS = $client->listTags( $Resources[0]->{id} );
    ok( @tgS == 0, 'list with 0 tags in resource ' . $Resources[0]->{id} );

    $idTg = $client->delTag( $Resources[0]->{id}, $valTg[1] );
    ok( !defined $idTg, "tag not deleted, it doesn't exist" );

    @tgS = $client->listTags(-111);
    ok( @tgS == 0, "not listing tags, doen't exit resource" );
}

END {
    kill 3, $pid;
    Smeagol::DataStore->clean();
}
