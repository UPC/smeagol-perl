use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'SmeagolServer' }
BEGIN { use_ok 'SmeagolServer::Controller::Event' }

ok( request('/event')->is_success, 'Request should succeed' );
done_testing();
