#!/usr/bin/perl
use Test::More tests => 24;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;

BEGIN {
    use_ok($_) for qw(Booking DataStore);
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
my $b1 = Booking->new(
    "description b1",
    datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 )
);

# 19:00 - 19:59
my $b2 = Booking->new(
    "description b2",
    datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 )
);

# 15:00 - 17:59
my $b3 = Booking->new(
    "description b3",
    datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17, 59 )
);

# 15:00 - 17:00
my $b4 = Booking->new(
    "description b4",
    datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17 )
);

# 16:00 - 16:29
my $b5 = Booking->new(
    "description b5",
    datetime( 2008, 4, 14, 16 ),
    datetime( 2008, 4, 14, 16, 29 )
);

# 16:29:00 - 16:29:01
my $b6 = Booking->new(
    "description b6",
    datetime( 2008, 4, 14, 16, 29, 0 ),
    datetime( 2008, 4, 14, 16, 29, 1 )
);

# 16:29:01 - 16:29:02
my $b7 = Booking->new(
    "description b7",
    datetime( 2008, 4, 14, 16, 29, 1 ),
    datetime( 2008, 4, 14, 16, 29, 2 )
);

# 17:00:00 - 19:00:00
my $b8 = Booking->new(
    "description b8",
    datetime( 2008, 4, 14, 17, 0, 0 ),
    datetime( 2008, 4, 14, 19, 0, 0 )
);

# 18:00:00 - 21:00:00
my $b9 = Booking->new(
    "description b9",
    datetime( 2008, 4, 14, 18, 0, 0 ),
    datetime( 2008, 4, 14, 21, 0, 0 )
);

# 21:00 - 21:00:01
my $b10 = Booking->new(
    "description b10",
    datetime( 2008, 4, 14, 21 ),
    datetime( 2008, 4, 14, 21, 0, 1 )
);

# 21:00 - 21:00:01
my $b11 = Booking->new(
    "description b11",
    datetime( 2009, 4, 14, 21 ),
    datetime( 2009, 4, 14, 21, 0, 1 )
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

# missing parameter(s)
my $wrong = Booking->new( "wrong", datetime( 2008, 4, 14, 16 ) );
ok( !defined($wrong), 'Booking->new with missing parameter' );

#to_xml booking test
my $booking1_as_hash = {
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
};
ok( Compare( $booking1_as_hash, XMLin( $b1->to_xml() ) ), 'to_xml booking' );

# from_xml booking test
my $booking_as_xml = '
<booking>
    <id>' . $b1->id . '</id>
    <description>' . $b1->description . '</description>
    <from>
        <year>2008</year>
        <month>4</month>
        <day>14</day>
        <hour>17</hour>
        <minute>0</minute>
        <second>0</second>
    </from>
    <to>
        <year>2008</year>
        <month>4</month>
        <day>14</day>
        <hour>18</hour>
        <minute>59</minute>
        <second>0</second>
    </to>
</booking>';

ok( $b1 == Booking->from_xml( $booking_as_xml, $b1->id ),
    'from_xml booking' );

# from_xml booking test (wrong XML)
my $booking_as_xml_wrong = Booking->from_xml( '
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
</booking>', $b1->id );
ok( !defined($booking_as_xml_wrong), 'from_xml booking (with wrong XML)' );

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

END { DataStore->clean() }
