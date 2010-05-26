use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'SmeagolServer' }
BEGIN { use_ok 'SmeagolServer::Controller::ResourceTag' }

ok( request('/resourcetag')->is_success, 'Request should succeed' );
done_testing();
