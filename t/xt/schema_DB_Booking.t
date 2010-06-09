use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok 'Catalyst::Test', 'V2::Server'; 
    use_ok 'DBICx::TestDatabase';
}

ok my ($res, $c) = ctx_request('/'), 'context object';  # make sure we got the context object...

my $schema = DBICx::TestDatabase->new('V2::Server::Schema');
my @bookings_aux = $c->model('DB::Booking')->all;

my @bookings;
my $booking;
foreach (@bookings_aux) {
  $booking = $_->id;
  push (@bookings, $booking);

}

diag(Dumper(\@bookings));

done_testing();
