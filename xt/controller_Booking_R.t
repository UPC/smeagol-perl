use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'SmeagolServer' }
BEGIN { use_ok 'SmeagolServer::Controller::Booking_R' }

ok( request('/booking_r')->is_success, 'Request should succeed' );
done_testing();
