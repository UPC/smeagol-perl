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

done_testing();
