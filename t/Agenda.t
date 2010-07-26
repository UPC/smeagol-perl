#!/usr/bin/perl
use Test::More tests => 26;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;
use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;
use Encode;
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(
        Smeagol::Booking
        Smeagol::Booking::ICal
        Smeagol::Agenda
        Smeagol::Agenda::ICal
        Smeagol::DataStore
    );

    Smeagol::DataStore::init();
}

# Make a DateTime object with some defaults
sub datetime {
    my ( $year, $month, $day, $hour, $minute ) = @_;

    return DateTime->new(
        year   => $year   || '2008',
        month  => $month  || '4',
        day    => $day    || '14',
        hour   => $hour   || '0',
        minute => $minute || '0',
    );
}

# 17:00 - 18:59
my $b1 = Smeagol::Booking->new(
    "b1",
    datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 ),
    "info b1",
);

# 19:00 - 19:59
my $b2 = Smeagol::Booking->new(
    "b2",
    datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 ),
    "info b2",
);

# 15:00 - 17:59
my $b3 = Smeagol::Booking->new(
    "b3",
    datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17, 59 ),
    "info b3",
);

# 15:00 - 17:00
my $b4 = Smeagol::Booking->new(
    "b4",
    datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17 ),
    "info b4",
);

# 16:00 - 16:29
my $b5 = Smeagol::Booking->new(
    "b5",
    datetime( 2008, 4, 14, 16 ),
    datetime( 2008, 4, 14, 16, 29 ),
    "info b5",
);

# Agenda Append Tests
my $ag = Smeagol::Agenda->new();

$ag->append($b1);
ok( $ag->contains($b1),  'b1 in ag' );
ok( !$ag->contains($b2), 'b2 not in ag' );

#toXML agenda test
my $agendaAsHash = {
    booking => {
        id          => $b1->id,
        description => $b1->description,
        from        => {
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 17,
            minute => 0,
            second => 0,
        },
        to => {
            year   => 2008,
            month  => 4,
            day    => 14,
            hour   => 18,
            minute => 59,
            second => 0,
        },
        info => $b1->info,
    },
};
ok( Compare( XMLin( $ag->toXML() ), $agendaAsHash ), 'toXML agenda' );

$ag->append($b2);
ok( $ag->size == 2 && $ag->contains($b2), 'b2 also in ag' );

$ag->append($b3);
ok( $ag->size == 2 && !$ag->contains($b3), 'b3 not in ag' );

$ag->append($b4);
ok( $ag->size == 2 && !$ag->contains($b4), 'b4 not in ag' );

# Agenda Remove Tests
ok( $ag->size == 2, 'ag has 2 slots' );

$ag->remove($b1);
ok( $ag->size == 1, 'ag has 1 slot' );

$ag->remove($b2);
ok( $ag->size == 0, 'ag has no slots' );

$ag->remove($b4);
ok( $ag->size == 0, 'remove non-existing b4 from ag' );

# Testing iCalendar features
{
    my $agenda = Smeagol::Agenda::ICal->new();
    ok( $agenda->size == 0, "agenda has no ical bookings" );

    my %dtstart1 = (
        year  => 2008,
        month => 4,
        day   => 14,
        hour  => 10,
    );
    my %dtend1 = (
        year  => 2008,
        month => 4,
        day   => 14,
        hour  => 11,
    );

    my $booking1 = Smeagol::Booking::ICal->new(
        "1st booking ical",
        DateTime->new(%dtstart1),
        DateTime->new(%dtend1),
    );
    $agenda->append($booking1);
    ok( $agenda->size == 1, "agenda has 1 ical booking" );

    my $entry1 = Data::ICal::Entry::Event->new();
    $entry1->add_properties(
        summary => "1st booking ical",
        dtstart => Date::ICal->new(%dtstart1)->ical,
        dtend   => Date::ICal->new(%dtend1)->ical,
    );

    my %dtstart2 = (
        year  => 2008,
        month => 4,
        day   => 14,
        hour  => 15,
    );
    my %dtend2 = (
        year  => 2008,
        month => 4,
        day   => 14,
        hour  => 16,
    );

    my $booking2 = Smeagol::Booking::ICal->new(
        "2nd booking ical",
        DateTime->new(%dtstart2),
        DateTime->new(%dtend2),
    );
    $agenda->append($booking2);
    ok( $agenda->size == 2, "agenda has 2 ical bookings" );

    my $entry2 = Data::ICal::Entry::Event->new();
    $entry2->add_properties(
        summary => "2nd booking ical",
        dtstart => Date::ICal->new(%dtstart2)->ical,
        dtend   => Date::ICal->new(%dtend2)->ical,
    );

    my $calendar = Data::ICal->new();
    $calendar->add_entry($entry1);
    $calendar->add_entry($entry2);

    my @expected = sort grep { !/^(?:PRODID)/ }
        split /\n/, $calendar->as_string;
    my @got = sort grep { !/^(?:PRODID)/ }
        split /\n/, "$agenda";

    is_deeply( \@got, \@expected, "looks like an vcalendar" );
}

# Testing UTF-8
{
    my $encoding    = "UTF-8";
    my $description = decode( $encoding, "àèòéíóú" );
    my $info        = decode( $encoding, "ïüçñ" );
    my $booking     = Smeagol::Booking->new(
        $description,
        datetime( 2008, 4, 14, 16 ),
        datetime( 2008, 4, 14, 16, 29 ), $info,
    );
    isa_ok( $booking, 'Smeagol::Booking' );
    is( $booking->description, $description, "description in UTF-8" );
    is( $booking->info,        $info,        "info in UTF-8" );

    my $agenda = Smeagol::Agenda->new();
    isa_ok( $agenda, 'Smeagol::Agenda' );

    $agenda->append($booking);
    ok( $agenda->contains($booking), 'booking added in agenda' );
    like( decode( 'UTF-8', "$agenda" ),
        qr/$description/, "UTF-8 description found in agenda" );
    like( decode( 'UTF-8', "$agenda" ),
        qr/$info/, "UTF-8 info found in agenda" );
}

END { Smeagol::DataStore->clean(); }
