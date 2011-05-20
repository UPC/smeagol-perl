use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;
use DateTime;
use DateTime::Duration;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Exception' }

my $j = JSON::Any->new;

#Request list of exceptions
ok( my $response = request GET '/exception',
    HTTP::Headers->new( Accept => 'application/json' )
);

is( $response->headers->{status}, '200', 'Response status is 200: OK' );

diag '###################################';
diag '##Requesting exceptions one by one###';
diag '###################################';
ok( my $exception_aux = $j->jsonToObj( $response->content ) );

my @exception = @{$exception_aux};
my $id;

foreach (@exception) {
    $id = $_->{id};
    ok( $response = request GET '/exception/' . $id, [] );
    is( $response->headers->{status}, '200', 'Response status is 200: OK' );
}
diag '\n';
diag '########################################';
diag '##Creating Exception with no recurrence###';
diag '########################################';

my $dt1 = DateTime->now->truncate( to => 'minute' );
my $dtstart = $dt1->clone->add( days => 0, hours => 0 );
my $dtend   = $dt1->clone->add( days => 0, hours => 2 );

ok( my $response_post = request POST '/exception',
    [   id_booking => "1",
        dtstart    => $dtstart,
        dtend      => $dtend,
        freq       => 'daily',
        interval   => 1
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);
diag $response_post->content;
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

diag '\n';
diag '###########################################';
diag '##Creating Exception with daily recurrence###';
diag '###########################################';

ok( $response_post = request POST '/exception',
    [   id_booking => "1",
        dtstart    => $dtstart,
        dtend      => $dtend,
        freq       => 'daily',
        interval   => 1,
        until      => $dtend->clone->add( days => 10 ),
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Exception with daily recurrence: " . $response_post->content;

ok( $exception_aux = $j->jsonToObj( $response_post->content ) );
$request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '\n';
diag '############################################';
diag '##Creating Exception with weekly recurrence###';
diag '############################################';

ok( $response_post = request POST '/exception',
    [   id_booking => "1",
        dtstart    => $dtstart,
        dtend      => $dtend,
        freq       => 'weekly',
        interval   => 1,
        until      => $dtend->clone->add( months => 4 ),
        by_day     => substr( lc( $dtstart->day_abbr ), 0, 2 ) . ","
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Exception with weekly recurrence: " . $response_post->content;
ok( $exception_aux = $j->jsonToObj( $response_post->content ) );
$request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '\n';
diag '############################################';
diag '##Creating Exception with monthly recurrence##';
diag '############################################';

ok( $response_post = request POST '/exception',
    [   id_booking   => "1",
        dtstart      => $dtstart,
        dtend        => $dtend,
        freq         => 'monthly',
        interval     => 1,
        until        => $dtend->clone->add( months => 4 ),
        by_day_month => $dtstart->day
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Exception with monthly recurrence: " . $response_post->content;
ok( $exception_aux = $j->jsonToObj( $response_post->content ) );
$request_DELETE = DELETE( 'exception/' . $exception_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '';
done_testing();

