use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Booking_S' }

my $j = JSON::Any->new;

#Request list of bookings
ok( request('/booking_s')->is_success, 'Request should succeed' );

ok(my $response = request GET '/booking_s', []);

diag 'Booking list: '.$response->content;
diag '###################################';
diag '##Requesting bookings one by one###';
diag '###################################';
my $bookings_aux = $j->jsonToObj($response->content);

my @bookings = @{$bookings_aux};
my $id;

foreach (@bookings) {
  $id = $_->{"id"};
  ok($response = request GET '/booking_s/'.$id, []);
  diag 'Booking '.$id.' '.$response->content;
  diag '###################################';
}


=head1
Create new booking
=cut

diag '#########Creating booking#########';
diag '###################################';

ok(my $response_post = request POST '/booking_s', [starts=>'2010-02-16T04:00:00', ends=>'2010-02-16T05:00:00', id_resource=>'1', id_event=>'1']);
diag $response_post->content;

=head1
Editing the last created booking
=cut

diag '##########Editing booking#########';
diag '###################################';

my $bid = @bookings+1;

#diag "ID: ".$id;
ok(my $response_put = request PUT '/booking_s/'.$bid, [starts=>'2010-02-16T04:00:00', ends=>'2010-02-16T05:00:00', id_resource=>'2', id_event=>'2']);
diag $response_put->content;

diag '#########Deleting booking#########';
diag '###################################';

my $ua = LWP::UserAgent->new;
my $request_del = HTTP::Request->new(DELETE => 'http://localhost:3000/booking_s/'.$bid);
ok($ua->request($request_del));

done_testing();
