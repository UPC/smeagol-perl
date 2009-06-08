#!/usr/bin/perl
use Test::More tests => 36;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;
use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;
use Encode;

BEGIN {
    use_ok($_) for qw(
        Smeagol::Booking
        Smeagol::Booking::ICal
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
    "description b1",
    datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 ),
    "info b1"
);

# 19:00 - 19:59
my $b2 = Smeagol::Booking->new(
    "description b2",
    datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 ),
    "info b2"
);

# 15:00 - 17:59
my $b3 = Smeagol::Booking->new(
    "description b3",
    datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17, 59 ),
    "info b3"
);

# 15:00 - 17:00
my $b4 = Smeagol::Booking->new(
    "description b4",
    datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17 ),
    "info b4"
);

# 16:00 - 16:29
my $b5 = Smeagol::Booking->new(
    "description b5",
    datetime( 2008, 4, 14, 16 ),
    datetime( 2008, 4, 14, 16, 29 ),
    "info b5"
);

# 16:29:00 - 16:29:01
my $b6 = Smeagol::Booking->new(
    "description b6",
    datetime( 2008, 4, 14, 16, 29, 0 ),
    datetime( 2008, 4, 14, 16, 29, 1 ),
    "info b6"
);

# 16:29:01 - 16:29:02
my $b7 = Smeagol::Booking->new(
    "description b7",
    datetime( 2008, 4, 14, 16, 29, 1 ),
    datetime( 2008, 4, 14, 16, 29, 2 ),
    "info b7"
);

# 17:00:00 - 19:00:00
my $b8 = Smeagol::Booking->new(
    "description b8",
    datetime( 2008, 4, 14, 17, 0, 0 ),
    datetime( 2008, 4, 14, 19, 0, 0 ),
    "info b8"
);

# 18:00:00 - 21:00:00
my $b9 = Smeagol::Booking->new(
    "description b9",
    datetime( 2008, 4, 14, 18, 0, 0 ),
    datetime( 2008, 4, 14, 21, 0, 0 ),
    "info b9"
);

# 21:00 - 21:00:01
my $b10 = Smeagol::Booking->new(
    "description b10",
    datetime( 2008, 4, 14, 21 ),
    datetime( 2008, 4, 14, 21, 0, 1 ),
    "info b10"
);

# 21:00 - 21:00:01
my $b11 = Smeagol::Booking->new(
    "description b11",
    datetime( 2009, 4, 14, 21 ),
    datetime( 2009, 4, 14, 21, 0, 1 ),
    "info b11"
);

# Booking->id getter and autoincrement
ok( $b1->id == 1,   'Booking->id getter' );
ok( $b11->id == 11, 'id increments after each Booking creation' );

# Booking->id setter
$b1->id(100);
ok( $b1->id == 100, 'Booking->id setter' );

$b1->id(1);    # undo previous modification

# Booking->description getter and setter
ok( $b1->description eq 'description b1', 'Booking->description getter' );
$b1->description('test');
ok( $b1->description eq 'test', 'Booking->description setter' );
$b1->description('description b1');    # undo previous modification

# Booking->info getter and setter
ok( $b1->info eq 'info b1', 'Booking->info getter' );
$b1->info('chachi pilongui');
ok( $b1->info eq 'chachi pilongui', 'Booking->info setter' );
$b1->info('info b1');                  # undo previous modification

# missing parameter(s)
my $wrong = Smeagol::Booking->new( "wrong", datetime( 2008, 4, 14, 16 ) );
ok( !defined($wrong), 'Booking->new with missing parameter' );

# Booking->info is optional
my $good = Smeagol::Booking->new(
    "good",
    datetime( 2008, 4, 14, 16 ),
    datetime( 2008, 4, 14, 17 )
);
ok( defined($good), 'Booking->new with missing info' );

#toXML booking test
my $booking1AsHash = {
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
};
ok( Compare( $booking1AsHash, XMLin( $b1->toXML() ) ), 'toXML booking' );

# newFromXML booking test
my $bookingAsXML = '
<booking>
    <id>' . $b1->id . '</id>
    <description>' . $b1->description . '</description>
    <from>
        <year>2008</year>
        <month>4</month>
        <day>14</day>
        <hour>17</hour>
        <minute>00</minute>
        <second>00</second>
    </from>
    <to>
        <year>2008</year>
        <month>4</month>
        <day>14</day>
        <hour>18</hour>
        <minute>59</minute>
        <second>00</second>
    </to>
    <info>' . $b1->info . '</info>
</booking>';

ok( $b1 == Smeagol::Booking->newFromXML( $bookingAsXML, $b1->id ),
    'newFromXML booking' );

# newFromXML booking test (wrong XML)
my $bookingAsWrongXML = Smeagol::Booking->newFromXML( '
<booking>
    <!-- <id> is missing! -->
    <!-- <description> is missing! -->
    <from>
        <year>2008</year>
        <month>4</month>
        <day>14</day>
        <hour>17</hour>
        <minute>0</minute>
        <second>0</second>
    </from>
    <!-- <to> is missing! -->
    <info>Lalalala</info>
</booking>', $b1->id );
ok( !defined($bookingAsWrongXML), 'newFromXML booking (with wrong XML)' );

# Booking Equality Tests
ok( $b1 != $b2, 'b1 != b2' );

# Booking Interlacing Tests
ok( !$b1->intersects($b2),   'b1 does not interlace b2' );
ok( $b1->intersects($b3),    'b1 interlaces b3' );
ok( $b1->intersects($b4),    'b1 interlaces b4' );
ok( $b4->intersects($b5),    'b4 interlaces b5' );
ok( $b5->intersects($b4),    'b5 interlaces b4' );
ok( $b6->intersects($b5),    'b6 interlaces b5' );
ok( $b6->intersects($b7),    'b6 interlaces b7' );
ok( $b4->intersects($b8),    'b4 interlaces b8' );
ok( $b2->intersects($b8),    'b2 interlaces b8' );
ok( $b9->intersects($b8),    'b9 interlaces b8' );
ok( $b9->intersects($b10),   'b9 interlaces b10' );
ok( !$b10->intersects($b11), 'b11 does not interlace b10' );

# Testing iCalendar
{
    my %dtstart = (
        year  => 2008,
        month => 4,
        day   => 14,
        hour  => 17
    );
    my %dtend = (
        year  => 2008,
        month => 4,
        day   => 14,
        hour  => 18
    );

    my $booking = Smeagol::Booking::ICal->new(
        "description ical",
        DateTime->new(%dtstart),
        DateTime->new(%dtend),
    );

    isa_ok( $booking, "Smeagol::Booking::ICal" );

    my $entry = Data::ICal::Entry::Event->new();
    $entry->add_properties(
        summary => "description ical",
        dtstart => Date::ICal->new(%dtstart)->ical,
        dtend   => Date::ICal->new(%dtend)->ical,
    );

    my @expected = sort grep { !/^(?:PRODID)/ }
        split /\n/, $entry->as_string;
    my @got = sort grep { !/^(?:PRODID)/ }
        split /\n/, "$booking";

    is_deeply( \@got, \@expected, "looks like an vcalendar" );

    my $xmlBooking = Smeagol::Booking->newFromXML( $booking->parent->toXML );
    ok( $booking == $xmlBooking, "ical == xml" );
    ok( $booking eq $xmlBooking, "ical eq xml" );

    my $icalBooking = $xmlBooking->ical;
    @got = sort grep { !/^(?:PRODID)/ }
        split /\n/, "$icalBooking";

    is_deeply( \@got, \@expected, "booking->ical works" );
};

# Testing UTF-8
{
    my $encoding    = "UTF-8";
    my $description = decode( $encoding, "àèòéíóú" );
    my $info        = decode( $encoding, "ïüñç" );
    my $b           = Smeagol::Booking->new(
        $description,
        datetime( 2008, 4, 14, 17 ),
        datetime( 2008, 4, 14, 18, 59 ), $info,
    );

    isa_ok( $b, 'Smeagol::Booking' );
    is( $b->description, $description, "description in UTF-8" );
    is( $b->info,        $info,        "info in UTF-8" );
}

END { Smeagol::DataStore->clean() }
