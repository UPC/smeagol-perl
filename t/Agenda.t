#!/usr/bin/perl
use Test::More tests => 13;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;

BEGIN { use_ok($_) for qw(Booking Agenda DataStore) }

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

# Agenda Append Tests
my $ag = Agenda->new();

$ag->append($b1);
ok( $ag->contains($b1),  'b1 in ag' );
ok( !$ag->contains($b2), 'b2 not in ag' );

#to_xml agenda test
my $agenda_as_hash = {
    booking => {
        id => $b1->id,
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
    },
};
ok( Compare( XMLin( $ag->to_xml() ), $agenda_as_hash ), 'to_xml agenda' );

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

END { DataStore->clean(); }
