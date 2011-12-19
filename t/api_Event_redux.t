#!perl

use strict;
use warnings;

BEGIN {
    require 't/TestingDB.pl';
}

use V2::Test;
use Test::More;
use utf8::all;

my $e = V2::Test->new( uri => '/event' );

my @events = $e->GET();

is_deeply( \@events, [], 'get empty list of events' );

my %ev1 = (
    description => 'event1',
    info        => 'info1',
    starts      => '2011-12-08T00:00:00',

    # FIXME: les dates s'arrodoneixen al minut
    #ends => '2011-12-08T23:59:59',
    ends => '2011-12-08T23:59:00',

    # FIXME (bug #355)
    #
    # Cal passar sempre la llista de tags i bookings.
    # smeagol/branches/tiquet_330_booking/lib/V2/Server/Schema/Result/TEvent.pm#L112
    #
    tags     => [],
    bookings => [],
);

my $id  = $e->POST( args => [ %ev1 ] );
my $out = $e->GET( id => $id );

is_deeply( $out, { %ev1, id => $id }, "create event1" );

@events = $e->GET();

is_deeply( \@events, [ $id ], 'list of 1 event' );

$ev1{'description'} = 'edited';
$e->PUT( id => $id, args => [ %ev1 ] );

@events = $e->GET();

is_deeply( \@events, [ $id ], 'still list of 1 event' );

$out = $e->GET( id => $id );

is_deeply( $out, { %ev1, id => $id }, "edit event1" );

$e->DELETE( id => $id );

@events = $e->GET();

is_deeply( \@events, [], 'delete gets empty list back' );

done_testing();
