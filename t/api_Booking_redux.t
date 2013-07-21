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
    frequency    => 'daily',
    interval     => 1,
);

my $id  = $b->POST( args => [ %book1 ] );
my $out = $b->GET( id => $id );
like_booking( $out, \%book1, $id, "create booking1" );

@bookings = $b->GET();
is_deeply( \@bookings, [ $id ], 'list of 1 booking' );

$book1{'info'} = 'edited-info';
$b->PUT( id => $id, args => [ %book1 ] );
@bookings = $b->GET();
is_deeply( \@bookings, [ $id ], 'still list of 1 booking' );

$out = $b->GET( id => $id );
like_booking( $out, \%book1, $id, "edit booking1" );

$b->DELETE( id => $id );
@bookings = $b->GET();
is_deeply( \@bookings, [], 'delete gets empty list back' );

done_testing();

#
# The resulting booking has more attributes than the original,
# so we only compare the result of the original attributes.
# Thus, we do not depend on DateTime internals regarding
# the attributes we did not define explicitly.
#
sub like_booking {
    my ( $out, $exp, $id, $msg ) = @_;

    my %out = %$out;
    my %expected = %$exp;
    $expected{'id'} = $id;

    my %got;
    @got{ keys %expected } = @out{ keys %expected };
    is_deeply( \%got, \%expected, "edit booking1" );
}
