use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Tag' }

my $j = JSON::Any->new;

ok( request('/tag')->is_success, 'Request should succeed' );

diag '###################################';
diag '########Requesting tag list########';
diag '###################################';

ok( my $response = request GET '/tag', [] );
diag 'Tag list: ' . $response->content;

diag '###################################';
diag '#### Requesting tags one by one####';
diag '###################################';
my $tag_aux = $j->jsonToObj( $response->content );

my @tag = @{$tag_aux};
my $id;

foreach (@tag) {
    $id = $_->{"id"};
    ok( $response = request GET '/tag/' . $id, [] );
    diag 'Tag ' . $id . ' ' . $response->content;
    diag '###################################';
}

diag '###################################';
diag '###########Creating tag ###########';
diag '###################################';

ok( my $response_post = request POST '/tag',
    [   name      => 'Test',
        description => ':-P',
    ]
);
diag $response_post->content;

diag '###################################';
diag '###########Editing tag ############';
diag '###################################';

ok( my $response_put = request PUT '/tag/Test'."?name=Edition_OK&description=:-X",
    [   name      => 'Edition_OK',
        description => ':-X',
    ]
);
diag $response_put->content;

diag '###################################';
diag '######### Deleting tag ############';
diag '###################################';

my $ua = LWP::UserAgent->new;
my $request_del
    = HTTP::Request->new( DELETE => 'http://localhost:3000/tag/Edition_OK');
diag $request_del->content;
ok( my $response_del = $ua->request($request_del) );
diag $response_del->content;

done_testing();
