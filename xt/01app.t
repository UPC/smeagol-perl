use strict;
use warnings;
use Test::More tests => 2;

BEGIN { $ENV{'TESTING_DB'} ||= 't/smeagol.db' }
BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }

ok( request('/')->is_success, 'Request should succeed' );
