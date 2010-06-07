use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Tag' }

my $j = JSON::Any->new;

#Comprovacio de que el controller tag existeix
ok( request('/tag')->is_success, 'Request should succeed' );

ok(my $response = request GET '/tag', []);

diag 'Tag list: '.$response->content;
diag '###################################';
diag '#####Requesting tag one by one#####';
diag '###################################';
my $tag_aux = $j->jsonToObj($response->content);

my @tag = @{$tag_aux};
my $id;

foreach (@tag) {
  $id = $_->{"id"};
  ok($response = request GET '/tag/'.$id, []);
  diag 'Tag '.$id.' '.$response->content;
  diag '###################################';
}

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
