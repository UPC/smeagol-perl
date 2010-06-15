use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'SmeagolServer' }
BEGIN { use_ok 'SmeagolServer::Controller::Tag' }

ok( request('/tag')->is_success, 'Request should succeed' );
diag '###################################';
diag '###########Creating tag ###########';
diag '###################################';

ok($response = request POST '/tag/', [name=>'testing_POST']);

ok($response = request GET '/tag/testing_POST', []);

diag '###################################';
diag '###########Editing tag ###########';
diag '###################################';

ok($response = request PUT '/tag/testing_POST', [name=>'testing_PUT']);

ok($response = request GET '/tag/testing_PUT', []);

diag '###################################';
diag '###########Deleting tag ###########';
diag '###################################';

my $ua = LWP::UserAgent->new;
my $request_del = HTTP::Request->new(DELETE => 'http://localhost:3000/tag/testing_PUT');
ok($ua->request($request_del));


done_testing();
