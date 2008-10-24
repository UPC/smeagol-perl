#!/usr/bin/perl

use Test::More tests => 18;

use DateTime;

use strict;
use warnings;

BEGIN { use_ok($_) for qw(Booking Agenda Resource) };

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
	
# Booking Equality Tests
ok( $b1 != $b2, 'b1 != b2' );

# Booking Interlacing Tests
ok( !$b1->intersects($b2), 'b1 does not interlace b2' );
ok(  $b1->intersects($b3), 'b1 interlaces b3' );
ok(  $b1->intersects($b4), 'b1 interlaces b4' );
ok(  $b4->intersects($b5), 'b4 interlaces b5' );
ok(  $b5->intersects($b4), 'b5 interlaces b4' );

# Agenda Append Tests
my $ag = Agenda->new();

$ag->append($b1);
ok( $ag->contains($b1), 'b1 in ag' );

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

# Resource creation Tests
my $r = Resource->from_xml(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <resource>
            <id>25</id>
            <description>aula chachipilongui</description>
        </resource>");
ok( $r->{id}   eq "25" && 
    $r->{desc} eq "aula chachipilongui", 
    'resource r created from XML string');

