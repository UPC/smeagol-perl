#!perl

use strict;
use warnings;

BEGIN {
    require 't/TestingDB.pl';
}

use V2::Test;
use Test::More;
use utf8::all;

my $res_id = V2::Test->new( uri => '/resource' )->POST( args => [
    description => 'resource_description',
    info        => 'resource_info',
]);

my $ev_id = V2::Test->new( uri => '/event' )->POST( args => [
    description => 'event_description',
    info        => 'event_info',
    starts      => '2011-12-08T00:00:00',
    ends        => '2011-12-08T23:59:00',
    tags        => '',
    bookings    => '',
]);

my $b = V2::Test->new( uri => '/booking' );

my @bookings = $b->GET();

is_deeply( \@bookings, [], 'get empty list of bookings' );

my %book1 = (
    info         => 'info1',
    dtstart      => '2011-12-08T00:00:00',
    dtend        => '2011-12-08T23:59:00',
    id_resource  => $res_id,
    id_event     => $ev_id,
    freq         => 'daily',
    interval     => 1,
#    by_minute    => '',
#    until        => '',
#    by_hour      => '',
#    by_day       => '',
#    by_month     => '',
#    by_day_month => '',
#    exception    => '',


    # FIXME (bug #355)
    #
    # Cal passar obligatòriament els tags '''com string'''.
    # smeagol/branches/tiquet_330_booking/lib/V2/Server/Controller/Booking.pm#L356
    #
    tags => [],
);

my $id  = $b->POST( args => [ %book1 ] );
my $out = $b->GET( id => $id );
delete $out->{'duration'};
delete $out->{'frequency'};
delete $out->{'until'};

is_deeply( $out, { %book1, id => $id }, "create booking1" );

@bookings = $b->GET();

is_deeply( \@bookings, [ $id ], 'list of 1 booking' );

$book1{'info'} = 'edited-info';
$b->PUT( id => $id, args => [ %book1 ] );

@bookings = $b->GET();

is_deeply( \@bookings, [ $id ], 'still list of 1 booking' );

$out = $b->GET( id => $id );
delete $out->{'duration'};
delete $out->{'frequency'};
delete $out->{'until'};

is_deeply( $out, { %book1, id => $id }, "edit booking1" );

$b->DELETE( id => $id );

@bookings = $b->GET();

is_deeply( \@bookings, [], 'delete gets empty list back' );

done_testing();
