use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;
use DateTime;
use DateTime::Duration;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Booking' }

my $j = JSON::Any->new;

#Request list of bookings
ok( my $response = request GET '/booking',
    HTTP::Headers->new(Accept => 'application/json'));

diag "Llista de bookings: ".$response->content;

diag '###################################';
diag '##Requesting bookings one by one###';
diag '###################################';
ok (my $booking_aux = $j->jsonToObj( $response->content ));

my @booking = @{$booking_aux};
my $id;

foreach (@booking) {
    $id = $_->{id};
    ok( $response = request GET '/booking/' . $id, [] );
    diag 'Booking ' . $id . ' ' . $response->content;
    diag '###################################';
}

diag '########################################';
diag '##Creating Booking with no recurrence###';
diag '########################################';

my $dt1 = DateTime->now->truncate( to => 'minute' );
my $dtstart = $dt1->clone->add(days=> 0, hours => 0);
my $dtend = $dt1->clone->add(days => 0, hours => 2);

ok(my $response_post = request POST '/booking',
    [
      id_event => "1",
      id_resource => "1",
      dtstart => $dtstart,
      dtend => $dtend,
      ],
    HTTP::Headers->new(Accept => 'application/json'));

diag "Nou booking sense recurrència: ".$response_post->content;

ok ($booking_aux = $j->jsonToObj( $response_post->content));

ok ($booking_aux->{id_event} eq 1,"ID event correct");
ok ($booking_aux->{id_resource} eq 1,"ID resource correct");
ok ($booking_aux->{dtstart} eq $dtstart,"DTSTART correct");
ok ($booking_aux->{dtend} eq $dtend,"DTEND correct");


my $ua_del = LWP::UserAgent->new;
my $request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/booking/' .$booking_aux->{id});
$request_del->header(Accept => 'application/json');

ok( $ua_del->request($request_del) );


diag '###########################################';
diag '##Creating Booking with daily recurrence###';
diag '###########################################';

ok($response_post = request POST '/booking',
    [
      id_event => "1",
      id_resource => "1",
      dtstart => $dtstart,
      dtend => $dtend,
      freq => 'daily',
      interval => 1,
      until => $dtend->clone->add(days => 10)
      ],
    HTTP::Headers->new(Accept => 'application/json'));

diag "Booking with daily recurrence: ".$response_post->content;

ok ($booking_aux = $j->jsonToObj( $response_post->content));
$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/booking/' .$booking_aux->{id});
$request_del->header(Accept => 'application/json');

ok( my $response = $ua_del->request($request_del) );
diag "Esborrem booking amb recurrència diaria: ".$response->content;

done_testing();
