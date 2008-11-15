#!/usr/bin/perl
use Test::More tests => 8;

use DateTime;

use strict;
use warnings;
use Data::Dumper;

BEGIN { use_ok($_) for qw(Booking) };

# Make a DateTime object with some defaults
sub datetime {
    my ($year, $month, $day, $hour, $minute) = @_;

    return DateTime->new(
        year   => $year   || '2008',
        month  => $month  || '4',
        day    => $day    || '14',
        hour   => $hour   || '0',
        minute => $minute || '0',
    );
}

# 17:00 - 18:59
my $b1 = Booking->new(datetime(2008, 4, 14, 17),
                      datetime(2008,4,14,18,59));
# 19:00 - 19:59
my $b2 = Booking->new(datetime(2008,4,14,19),
                      datetime(2008,4,14,19,59));
# 15:00 - 17:59
my $b3 = Booking->new(datetime(2008,4,14,15),
                      datetime(2008,4,14,17,59));
# 15:00 - 17:00
my $b4 = Booking->new(datetime(2008,4,14,15),
                      datetime(2008,4,14,17));
# 16:00 - 16:29
my $b5 = Booking->new(datetime(2008,4,14,16),
                      datetime(2008,4,14,16,29));

#to_xml booking test
ok($b1->to_xml() eq "<booking><from>2008-04-14T17:00:00</from><to>2008-04-14T18:59:00</to></booking>", 'to_xml booking');

# Booking Equality Tests
ok( $b1 != $b2, 'b1 != b2' );

# Booking Interlacing Tests
ok( !$b1->intersects($b2), 'b1 does not interlace b2' );
ok(  $b1->intersects($b3), 'b1 interlaces b3' );
ok(  $b1->intersects($b4), 'b1 interlaces b4' );
ok(  $b4->intersects($b5), 'b4 interlaces b5' );
ok(  $b5->intersects($b4), 'b5 interlaces b4' );

