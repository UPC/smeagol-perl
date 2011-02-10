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
BEGIN { use_ok 'V2::Server::Controller::Exception' }

my $j = JSON::Any->new;

#Request list of exceptions
ok( my $response = request GET '/exception',
    HTTP::Headers->new(Accept => 'application/json'));

diag "Llista de exceptions: ".$response->content;

diag '###################################';
diag '##Requesting exceptions one by one###';
diag '###################################';
ok (my $exception_aux = $j->jsonToObj( $response->content ));

my @exception = @{$exception_aux};
my $id;

foreach (@exception) {
    $id = $_->{id};
    ok( $response = request GET '/exception/' . $id, [] );
    diag 'Exception ' . $id . ' ' . $response->content;
    diag '###################################';
}
diag '\n';
diag '########################################';
diag '##Creating Exception with no recurrence###';
diag '########################################';

my $dt1 = DateTime->now->truncate( to => 'minute' );
my $dtstart = $dt1->clone->add(days=> 0, hours => 0);
my $dtend = $dt1->clone->add(days => 0, hours => 2);

ok(my $response_post = request POST '/exception',
    [
      id_booking => "1",
      dtstart => $dtstart,
      dtend => $dtend,
      freq => 'daily',
      interval => 1
      ],
    HTTP::Headers->new(Accept => 'application/json'));

diag "Nou exception sense recurrència: ".$response_post->content;

ok ($exception_aux = $j->jsonToObj( $response_post->content));

ok ($exception_aux->{id_event} eq 1,"ID event correct");
ok ($exception_aux->{id_resource} eq 1,"ID resource correct");
ok ($exception_aux->{dtstart} eq $dtstart,"DTSTART correct");
ok ($exception_aux->{dtend} eq $dtend,"DTEND correct");


my $ua_del = LWP::UserAgent->new;
my $request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/exception/' .$exception_aux->{id});
$request_del->header(Accept => 'application/json');

ok( $ua_del->request($request_del) );

diag '\n';
diag '###########################################';
diag '##Creating Exception with daily recurrence###';
diag '###########################################';

ok($response_post = request POST '/exception',
    [
      id_booking => "1",
      dtstart => $dtstart,
      dtend => $dtend,
      freq => 'daily',
      interval => 1,
      until => $dtend->clone->add(days => 10),
      ],
    HTTP::Headers->new(Accept => 'application/json'));

diag "Exception with daily recurrence: ".$response_post->content;

ok ($exception_aux = $j->jsonToObj( $response_post->content));
$ua_del = LWP::UserAgent->new;
$request_del
    = HTTP::Request->new( DELETE => 'http://localhost:3000/exception/' . $exception_aux->{id} );
ok( $ua_del->request($request_del) );

ok( my $response = $ua_del->request($request_del) );
diag "Esborrem exception amb recurrència diaria: ".$response->content;

diag '\n';
diag '############################################';
diag '##Creating Exception with weekly recurrence###';
diag '############################################';

ok($response_post = request POST '/exception',
    [
      id_booking => "1",
      dtstart => $dtstart,
      dtend => $dtend,
      freq => 'weekly',
      interval => 1,
      until => $dtend->clone->add(months => 4),
      by_day => substr(lc($dtstart->day_abbr),0,2).","
      ],
    HTTP::Headers->new(Accept => 'application/json'));

diag "Exception with weekly recurrence: ".$response_post->content;
ok ($exception_aux = $j->jsonToObj( $response_post->content));
$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/exception/' .$exception_aux->{id});
$request_del->header(Accept => 'application/json');
ok( $response = $ua_del->request($request_del) );

diag '\n';
diag '############################################';
diag '##Creating Exception with monthly recurrence##';
diag '############################################';

ok($response_post = request POST '/exception',
    [
      id_booking => "1",
      dtstart => $dtstart,
      dtend => $dtend,
      freq => 'monthly',
      interval => 1,
      until => $dtend->clone->add(months => 4),
      by_day_month => $dtstart->day
      ],
    HTTP::Headers->new(Accept => 'application/json'));

diag "Exception with monthly recurrence: ".$response_post->content;
ok ($exception_aux = $j->jsonToObj( $response_post->content));
$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/exception/' .$exception_aux->{id});
$request_del->header(Accept => 'application/json');
ok( $response = $ua_del->request($request_del) );


done_testing();

