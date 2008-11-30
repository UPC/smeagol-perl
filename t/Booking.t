#!/usr/bin/perl
use Test::More tests => 11;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;

BEGIN { use_ok($_) for qw(Booking) }

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
my $b1 = Booking->new( datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 ) );

# 19:00 - 19:59
my $b2 = Booking->new( datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 ) );

# 15:00 - 17:59
my $b3 = Booking->new( datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17, 59 ) );

# 15:00 - 17:00
my $b4 = Booking->new( datetime( 2008, 4, 14, 15 ),
    datetime( 2008, 4, 14, 17 ) );

# 16:00 - 16:29
my $b5 = Booking->new( datetime( 2008, 4, 14, 16 ),
    datetime( 2008, 4, 14, 16, 29 ) );

# missing parameter(s)
my $wrong = Booking->new( datetime( 2008, 4, 14, 16 ) );
ok( !defined($wrong), 'Booking->new with missing parameter' );

#to_xml booking test
my $booking1_as_hash = {
    from => {
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
my $booking_as_xml = <<'EOF';
<booking>
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
</booking>
EOF

ok( $b1 == Booking->from_xml($booking_as_xml), 'from_xml booking' );

# from_xml booking test (wrong XML)
my $booking_as_xml_wrong = Booking->from_xml( '
<booking>
    <from>
        <year>2008</year>
        <month>4</month>
        <day>14</day>
        <hour>17</hour>
        <minute>0</minute>
        <second>0</second>
    </from>
    <!-- <to> is missing! -->
</booking>' );
ok( !defined($booking_as_xml_wrong), 'from_xml booking (with wrong XML)' );

# Booking Equality Tests
ok( $b1 != $b2, 'b1 != b2' );

# Booking Interlacing Tests
ok( !$b1->intersects($b2), 'b1 does not interlace b2' );
ok( $b1->intersects($b3),  'b1 interlaces b3' );
ok( $b1->intersects($b4),  'b1 interlaces b4' );
ok( $b4->intersects($b5),  'b4 interlaces b5' );
ok( $b5->intersects($b4),  'b5 interlaces b4' );

END { unlink </tmp/*.db> }
