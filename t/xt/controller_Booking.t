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
ok( request('/booking')->is_success, 'Request should succeed' );

ok( my $response = request GET '/booking', [] );

diag 'Booking list: ' . $response->content;
diag '###################################';
diag '##Requesting bookings one by one###';
diag '###################################';
my $bookings_aux= $j->from_json( $response->content );
my @bookings = @{$bookings_aux};
my $id;

foreach (@bookings) {
    $id = $_->{id};
    diag 'Booking ID: '.$id;
    ok( $response = request GET '/booking/' .$id, [] );
    diag 'Booking '.$id.' '.$response->content;
    diag '###################################';
}

=head1
Create new booking
=cut

diag '#########Creating booking#########';
diag '###################################';
my $duration = DateTime::Duration->new(hours   => 2);
my $start = DateTime->now();
my $end = $start->clone->add_duration($duration);


ok( my $response_post = request POST '/booking',
    [   starts      => $start,
        ends        => $end,
        id_resource => "1",
        id_event    => "1"
    ]
);
diag $response_post->content;

my $booking_aux= $j->from_json( $response_post->content );
my @booking = @{$booking_aux};
my $bid;

foreach (@booking){
      $bid = $_->{id};
}


=head1
Editing the last created booking
=cut

diag '##########Editing booking#########';
diag '###################################';
diag "Last Booking ID: ".$bid;

ok( my $response_put = request PUT '/booking/'.$bid,
      {   starts      => $start,
      ends        => $end,
      id_resource => "2",
      id_event    => "2",}
    );

diag $response_put->content;

diag '#########Deleting booking#########';
diag '###################################';

my $ua          = LWP::UserAgent->new;
my $request_del = HTTP::Request->new(
    DELETE => 'http://localhost:3000/booking/' . $bid );
ok( $ua->request($request_del) );

done_testing();
