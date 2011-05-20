use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;
use DateTime;
use DateTime::Duration;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Booking' }

my $j = JSON::Any->new;

#Request list of bookings
ok( my $response = request GET '/booking',
    HTTP::Headers->new( Accept => 'application/json' ) );

diag "Llista de bookings: " . $response->content;

diag '###################################';
diag '##Requesting bookings one by one###';
diag '###################################';
ok( my $booking_aux = $j->jsonToObj( $response->content ) );

my @booking = @{$booking_aux};
my $id;

foreach (@booking) {
    $id = $_->{id};
    ok( $response = request GET '/booking/' . $id, [] );
    diag 'Booking ' . $id . ' ' . $response->content;
    diag '###################################';
}
diag '\n';
diag '########################################';
diag '##Creating Booking with no recurrence###';
diag '########################################';

my $dt1 = DateTime->now->truncate( to => 'minute' );
my $dtstart = $dt1->clone->add( days => 0, hours => 0 );
my $dtend   = $dt1->clone->add( days => 0, hours => 2 );

ok( my $response_post = request POST '/booking',
    [   id_event    => "1",
        id_resource => "1",
        info        => "Info testing",
	tags        => 'tag_booking',
        dtstart     => $dtstart,
        dtend       => $dtend,
        freq        => 'daily',
        interval    => 1
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Nou booking sense recurrència: " . $response_post->content;

ok( $booking_aux = $j->jsonToObj( $response_post->content ) );

ok( $booking_aux->{id_event}    eq 1,              "ID event correct" );
ok( $booking_aux->{info}        eq "Info testing", "Info correct" );
ok( $booking_aux->{id_resource} eq 1,              "ID resource correct" );
ok( $booking_aux->{dtstart}     eq $dtstart,       "DTSTART correct" );
ok( $booking_aux->{dtend}       eq $dtend,         "DTEND correct" );

my $request_DELETE = DELETE( 'booking/' . $booking_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( my $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '\n';
diag '###########################################';
diag '##Creating Booking with daily recurrence###';
diag '###########################################';

ok( $response_post = request POST '/booking',
    [   id_event    => "1",
        id_resource => "1",
        info        => "Info testing",
        tags        => 'tag_booking',
        dtstart     => $dtstart,
        dtend       => $dtend,
        freq        => 'daily',
        interval    => 1,
        until       => $dtend->clone->add( days => 10 ),
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Booking with daily recurrence: " . $response_post->content;

ok( $booking_aux = $j->jsonToObj( $response_post->content ) );

ok( $booking_aux->{id_event}    eq 1,              "ID event correct" );
ok( $booking_aux->{info}        eq "Info testing", "Info correct" );
ok( $booking_aux->{id_resource} eq 1,              "ID resource correct" );
ok( $booking_aux->{dtstart}     eq $dtstart,       "DTSTART correct" );
ok( $booking_aux->{dtend}       eq $dtend,         "DTEND correct" );
ok( $booking_aux->{frequency}   eq 'daily',        "freq correct" );
ok( $booking_aux->{interval}    eq 1,              "interval correct" );
ok( $booking_aux->{until} eq $dtend->clone->add( days => 10 ),
    "until correct" );

$request_DELETE = DELETE( 'booking/' . $booking_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '\n';
diag '############################################';
diag '##Creating Booking with weekly recurrence###';
diag '############################################';

ok( $response_post = request POST '/booking',
    [   id_event    => "1",
        id_resource => "1",
        info        => "Info testing",
        tags        => 'tag_booking',
        dtstart     => $dtstart,
        dtend       => $dtend,
        freq        => 'weekly',
        interval    => 1,
        until       => $dtend->clone->add( months => 4 ),
        by_day      => substr( lc( $dtstart->day_abbr ), 0, 2 ) . ","
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Booking with weekly recurrence: " . $response_post->content;

ok( $booking_aux = $j->jsonToObj( $response_post->content ) );

ok( $booking_aux->{id_event}    eq 1,              "ID event correct" );
ok( $booking_aux->{info}        eq "Info testing", "Info correct" );
ok( $booking_aux->{id_resource} eq 1,              "ID resource correct" );
ok( $booking_aux->{dtstart}     eq $dtstart,       "DTSTART correct" );
ok( $booking_aux->{dtend}       eq $dtend,         "DTEND correct" );
ok( $booking_aux->{frequency}   eq 'weekly',       "freq correct" );
ok( $booking_aux->{interval}    eq 1,              "interval correct" );
ok( $booking_aux->{until} eq $dtend->clone->add( months => 4 ),
    "until correct" );

$request_DELETE = DELETE( 'booking/' . $booking_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '\n';
diag '############################################';
diag '##Creating Booking with monthly recurrence##';
diag '############################################';

ok( $response_post = request POST '/booking',
    [   id_event     => "1",
        id_resource  => "1",
        info         => "Info testing",
        tags        => 'tag_booking',  
        dtstart      => $dtstart,
        dtend        => $dtend,
        freq         => 'monthly',
        interval     => 1,
        until        => $dtend->clone->add( months => 4 ),
        by_day_month => $dtstart->day
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Booking with monthly recurrence: " . $response_post->content;

ok( $booking_aux = $j->jsonToObj( $response_post->content ) );

ok( $booking_aux->{id_event}    eq 1,              "ID event correct" );
ok( $booking_aux->{info}        eq "Info testing", "Info correct" );
ok( $booking_aux->{id_resource} eq 1,              "ID resource correct" );
ok( $booking_aux->{dtstart}     eq $dtstart,       "DTSTART correct" );
ok( $booking_aux->{dtend}       eq $dtend,         "DTEND correct" );
ok( $booking_aux->{frequency}   eq 'monthly',      "freq correct" );
ok( $booking_aux->{interval}    eq 1,              "interval correct" );
ok( $booking_aux->{until} eq $dtend->clone->add( months => 4 ),
    "until correct" );

$request_DELETE = DELETE( 'booking/' . $booking_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

diag '\n';
diag '#################################################################';
diag '##Creating Booking with daily recurrence + 1 simple exception ###';
diag '#################################################################';

my $exception = $dtend->clone->add( days => 1 )->ymd;

ok( $response_post = request POST '/booking',
    [   id_event    => "1",
        id_resource => "1",
        info        => "Info testing",
        tags        => 'tag_booking',
        dtstart     => $dtstart,
        dtend       => $dtend,
        freq        => 'daily',
        interval    => 1,
        until       => $dtend->clone->add( days => 2 ),
        exception   => '{"exception": "' . $exception . '" }',
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Booking with daily recurrence + simple exception: "
    . $response_post->content;

ok( $booking_aux = $j->jsonToObj( $response_post->content ) );

ok( $booking_aux->{id_event}    eq 1,              "ID event correct" );
ok( $booking_aux->{info}        eq "Info testing", "Info correct" );
ok( $booking_aux->{id_resource} eq 1,              "ID resource correct" );
ok( $booking_aux->{dtstart}     eq $dtstart,       "DTSTART correct" );
ok( $booking_aux->{dtend}       eq $dtend,         "DTEND correct" );
ok( $booking_aux->{frequency}   eq 'daily',        "freq correct" );
ok( $booking_aux->{interval}    eq 1,              "interval correct" );
ok( $booking_aux->{until} eq $dtend->clone->add( days => 2 ),
    "until correct" );

$request_DELETE = DELETE( 'booking/' . $booking_aux->{id} );
$request_DELETE->header( Accept => 'application/json' );
ok( $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

done_testing();
