#!/usr/bin/perl

use Test::More tests => 52;

use strict;
use warnings;
use Data::Dumper;

use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

BEGIN {
    use_ok($_) for qw(Server Client DataStore);
}

my $server_port = 8000;
my $server      = "http://localhost:$server_port";
my $pid         = Server->new($server_port)->background();

my $client = Client->new();
ok( !defined $client, 'client not created' );

$client = Client->new($server);
ok( ref $client eq 'Client', 'client created' );

my @idResources;
my @Resources;
my $idRes;
my $dataRes;
my $idBook;
my $dataBoo;
my @idBookings;
my @Bookings;
my $idAg;

# Extracts the Resource ID from a given Resource REST URL
sub id_resource {
    my ($url) = shift;

    if ( $url =~ /\/resource\/(\w+)/ ) {
        return $1;
    }
    else {
        return;
    }
}

sub id_resource_booking {
    my ($url) = shift;

    if ( $url =~ /resource\/(\d+)\/booking\/(\d+)/ ) {
        return ( $1, $2 );
    }
    else {
        return;
    }
}

# Testing retrieve empty resource list
{
    @idResources = $client->listResources();
    ok( @idResources == 0, 'list resources empty' );
}

# Testing resource creation and retrieving not an empty list
{
    push @Resources, $client->createResource( "aula", "hora" );
    ok( defined $Resources[0],
        'created resource ' . id_resource( $Resources[0] ) );

    @idResources = $client->listResources();
    ok( $idResources[0] eq $Resources[0],
        'resource ' . id_resource( $Resources[0] ) . ' at list' );

    push @Resources,
        $idRes = $client->createResource( "projector", "minuts" );
    ok( defined $Resources[1],
        'created resource ' . id_resource( $Resources[1] ) );

    @idResources = $client->listResources();
    ok( @idResources == 2, 'list resources 2 element' );

    push @Resources, $idRes = $client->createResource( "projector", "dia" );
    ok( defined $Resources[2],
        'created resource ' . id_resource( $Resources[2] ) );

    @idResources = $client->listResources();
    ok( @idResources == 3, 'list resources 3 element' );

    ok( $idResources[0] eq $Resources[0],
        'resource ' . id_resource( $Resources[0] ) . ' begin' );
    ok( $idResources[1] eq $Resources[1],
        'resource ' . id_resource( $Resources[1] ) . ' between' );
    ok( $idResources[2] eq $Resources[2],
        'resource ' . id_resource( $Resources[2] ) . ' end' );
}

#Testing resource updating and getting
{
    $idRes = $client->updateResource( id_resource( $Resources[0] ),
        "aulaaaaaa", "hora" );
    ok( $idRes eq $Resources[0],
        'updated resource ' . id_resource( $Resources[0] ) );

    $dataRes = $client->getResource( id_resource( $Resources[0] ) );
    ok( $dataRes->{granularity} eq 'hora'
            && $dataRes->{description} eq 'aulaaaaaa'
            && !defined $dataRes->{agenda},
        'get resource ' . id_resource( $Resources[0] )
    );

    $idRes = $client->updateResource( id_resource( $Resources[0] ),
        "aula", "hora" );
    ok( $idRes eq $Resources[0],
        'updated resource ' . id_resource( $Resources[0] ) );

    $dataRes = $client->getResource( id_resource( $Resources[0] ) );
    ok( $dataRes->{granularity} eq 'hora'
            && $dataRes->{description} eq 'aula'
            && !defined $dataRes->{agenda},
        'get resource ' . id_resource( $Resources[0] )
    );

    @idResources = $client->listResources();
    ok( $idResources[0] eq $Resources[0],
        'resource ' . id_resource( $Resources[0] ) . ' at list' );

    $idRes = $client->updateResource( id_resource( $Resources[1] ),
        "projector", "hora" );
    ok( $idRes eq $Resources[1],
        'updated resource ' . id_resource( $Resources[1] ) );

    $dataRes = $client->getResource( id_resource( $Resources[1] ) );
    ok( $dataRes->{granularity} eq 'hora'
            && $dataRes->{description} eq 'projector'
            && !defined $dataRes->{agenda},
        'get resource ' . id_resource( $Resources[1] )
    );
}

#Testing deleting resource
{
    @idResources = $client->listResources();
    ok( @idResources == 3, 'list resources not empty' );

    $idRes = $client->delResource( id_resource( $Resources[0] ) );
    ok( $idRes eq id_resource( $Resources[0] ),
        'deleted resource ' . id_resource( $Resources[0] ) );

    @idResources = $client->listResources();
    ok( @idResources == 2, 'list resources not empty' );

    $idRes = $client->delResource( id_resource( $Resources[2] ) );
    ok( $idRes eq id_resource( $Resources[2] ),
        'deleted resource ' . id_resource( $Resources[2] ) );

    @idResources = $client->listResources();
    ok( @idResources == 1, 'list resources not empty' );
    ok( $idResources[0] eq $Resources[1],
        'remining resource is ' . id_resource( $Resources[1] ) );
}

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

#Testing retrieve Agenda empty
{
    @idBookings = $client->listBookings( id_resource( $Resources[1] ) );
    ok( @idBookings == 0, 'empty Agenda at ' . id_resource( $Resources[1] ) );
}

#Testing create booking
{
    push @Bookings,
        $client->createBooking( id_resource( $Resources[1] ),
        $desc, $from, $to, $info );
    ok( defined $Bookings[0],
        'booking created ' . id_resource( $Bookings[0] ) );

    push @Bookings,
        $client->createBooking( id_resource( $Resources[1] ),
        $desc2, $from2, $to2, $info2 );
    ok( defined $Bookings[1],
        'booking created ' . id_resource( $Bookings[1] ) );

    push @Bookings,
        $client->createBooking( id_resource( $Resources[1] ),
        $desc, $from, $to, $info );
    ok( !defined $Bookings[2], 'booking not created, intersection' );

    push @Bookings,
        $client->createBooking( id_resource( $Resources[1] ),
        $desc3, $from3, $to3, $info3 );
    ok( defined $Bookings[3],
        'booking created ' . id_resource( $Bookings[3] ) );

    my $ical1
        = $client->getBookingICal( id_resource_booking( $Bookings[0] ) );
    my $ical2 = $client->listBookingsICal( id_resource( $Resources[1] ) );

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
    @idBookings = $client->listBookings( id_resource( $Resources[1] ) );
    ok( @idBookings == 3,
        'not empty Agenda at ' . id_resource( $Resources[1] ) );

    @idBookings = $client->listBookings( id_resource( $Resources[0] ) );
    ok( !defined $idBookings[0],
        'not empty Agenda at ' . id_resource( $Resources[0] ) );

}

#Testing retrieve and delete booking
{
    $dataBoo = $client->getBooking( id_resource_booking( $Bookings[1] ) );
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
            . id_resource( $Bookings[1] )
            . ' booking '
            . id_resource_booking( $Bookings[1] )
            . '-> retrieved'
    );

    $dataBoo = $client->getBooking( id_resource_booking( $Bookings[0] ) );
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
            . id_resource( $Bookings[0] )
            . ' booking '
            . id_resource_booking( $Bookings[0] )
            . '-> retrieved'
    );

    $idBook = $client->delBooking( id_resource_booking( $Bookings[0] ) );
    ok( $idBook eq id_resource_booking( $Bookings[0] ),
        'deleted booking ' . id_resource_booking( $Bookings[0] )
    );

    $dataBoo = $client->getBooking( id_resource_booking( $Bookings[0] ) );
    ok( !defined $dataBoo, 'retrieving booking not existent' );

    $idBook = $client->delBooking( $Resources[0], 1 );
    ok( !defined $idBook, 'not deleted booking, resource not existent' );

    $idBook = $client->delBooking( $Resources[1], -100 );
    ok( !defined $idBook, 'not deleted booking, booking not existent' );
}

#Testing retrieve Agenda not empty after deleting
{
    @idBookings = $client->listBookings( id_resource( $Resources[1] ) );
    ok( @idBookings == 2,
        'not empty Agenda at ' . id_resource( $Resources[1] ) );
}

#Testing update Booking
{
    $idBook = $client->updateBooking( id_resource_booking( $Bookings[0] ),
        $desc, $from, $to );
    ok( !defined $idBook, 'not updated booking, not existent resource' );

    $idBook = $client->updateBooking( id_resource( $Resources[2] ),
        1, $desc, $from, $to );
    ok( !defined $idBook, 'not updated booking, not existent resource' );

    $idBook = $client->updateBooking( id_resource( $Resources[1] ),
        -555, $desc, $from, $to );
    ok( !defined $idBook, 'not updated booking, not existent booking' );

    $idBook = $client->updateBooking( id_resource_booking( $Bookings[1] ),
        $desc2, $from2, $to2 );
    ok( defined $idBook, 'updated booking ' . $Bookings[1] );

    $dataBoo = $client->getBooking( id_resource_booking( $Bookings[1] ) );
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
        'retrieved booking updated' . $Bookings[1]
    );

    $idBook = $client->updateBooking( id_resource_booking( $Bookings[3] ),
        $desc2, $from2, $to2 );
    ok( !defined $idBook,
        'not updated booking, intersection '
            . id_resource_booking( $Bookings[3] )
    );

    $idBook = $client->updateBooking( id_resource_booking( $Bookings[3] ),
        $desc, $from, $to );
    ok( defined $idBook, 'updated booking ' . $idBook );

    $dataBoo = $client->getBooking( id_resource_booking( $Bookings[3] ) );
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
        'retrieved booking updated' . $Bookings[3]
    );

}

END {
    kill 3, $pid;
    DataStore->clean();
}
