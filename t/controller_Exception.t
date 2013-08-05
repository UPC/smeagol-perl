use strict;
use warnings;

use Test::More;
use Data::Dumper;
use JSON::Any;
use DateTime;
use DateTime::Duration;

use lib 't/lib';
use HTTP::Request::Common::Bug65843 qw/GET POST PUT DELETE/;

BEGIN { require 't/TestingDB.pl' }
BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Exception' }

my $j = JSON::Any->new;

#Request list of exceptions
ok( my $response = request GET '/exception' );

is( $response->headers->{status}, '200', 'Response status is 200: OK' );

ok( my $exception_aux = $j->jsonToObj( $response->content ) );

my @exception = @{$exception_aux};
my $id;

foreach (@exception) {
    $id = $_->{id};
    ok( $response = request GET '/exception/' . $id, [] );
    is( $response->headers->{status}, '200', 'Response status is 200: OK' );
}

my $dt1 = DateTime->now->truncate( to => 'minute' );
my $dtstart = $dt1->clone->add( days => 0, hours => 0 );
my $dtend   = $dt1->clone->add( days => 0, hours => 2 );

my $response_post = request POST '/resource', [
    description => 'DESC',
    info        => 'INFO',
];
ok( $response_post->is_success, 'New resource' );
$response_post = request POST '/event', [
    description => 'DESC',
    info        => 'INFO',
    starts      => $dtstart,
    ends        => $dtend,
];
ok( $response_post->is_success, 'New event' );
$response_post = request POST '/booking', [
    id_resource => 1,
    id_event    => 1,
    dtstart     => $dtstart,
    dtend       => $dtend,
];
ok( $response_post->is_success, 'New booking' );

ok( $response_post = request POST '/exception',
    [   id_booking => "1",
        dtstart    => $dtstart,
        dtend      => $dtend,
        freq       => 'daily',
        interval   => 1
    ],
);

is( $response_post->headers->{status},
    '201', 'Response status is 201: Created' );

ok( $exception_aux = $j->jsonToObj( $response_post->content ) );

ok( $exception_aux->{dtstart} eq $dtstart, "DTSTART correct" );
ok( $exception_aux->{dtend}   eq $dtend,   "DTEND correct" );

my $request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( my $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

ok( $response_post = request POST '/exception',
    [   id_booking => "1",
        dtstart    => $dtstart,
        dtend      => $dtend,
        freq       => 'daily',
        interval   => 1,
        until      => $dtend->clone->add( days => 10 ),
    ],
);

ok( $exception_aux = $j->jsonToObj( $response_post->content ) );
$request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

ok( $response_post = request POST '/exception',
    [   id_booking => "1",
        dtstart    => $dtstart,
        dtend      => $dtend,
        freq       => 'weekly',
        interval   => 1,
        until      => $dtend->clone->add( months => 4 ),
        by_day     => substr( lc( $dtstart->day_abbr ), 0, 2 ) . ","
    ],
);

ok( $exception_aux = $j->jsonToObj( $response_post->content ) );
$request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

ok( $response_post = request POST '/exception',
    [   id_booking   => "1",
        dtstart      => $dtstart,
        dtend        => $dtend,
        freq         => 'monthly',
        interval     => 1,
        until        => $dtend->clone->add( months => 4 ),
        by_day_month => $dtstart->day
    ],
);

ok( $exception_aux = $j->jsonToObj( $response_post->content ) );
ok( $response = request GET '/exception/' . $exception_aux->{id}, [] );
is( $response->headers->{status}, '200', 'Response status is 200: OK' );

ok( my $response_put = request PUT '/exception/' . $exception_aux->{id}, [
    id_booking   => 1,
    dtstart      => $dtstart,
    dtend        => $dtend,
    freq         => 'monthly',
    interval     => 1,
    until        => $dtend->clone->add( months => 5 ),
    by_day_month => $dtstart->day
]);
is( $response->headers->{status}, '200', 'Response status is 200: OK' );

$request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

done_testing();

