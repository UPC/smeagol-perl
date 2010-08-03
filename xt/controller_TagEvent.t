use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::TagEvent' }

ok( request('/tagevent')->is_success, 'Request should succeed' );
done_testing();
