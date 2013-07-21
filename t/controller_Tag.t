use strict;
use warnings;
use Test::More;
use JSON::Any;

use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;

BEGIN { require 't/TestingDB.pl' }
BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Tag' }

my $j = JSON::Any->new;

#Request list of bookings

ok( my $response = request GET '/tag' );
ok( $response->is_success, 'Request should succeed' );

ok( my $tag_aux = $j->jsonToObj( $response->content ) );

my @tag = @{$tag_aux};
my $id;

foreach (@tag) {
    $id = $_->{id};
    ok( $response = request GET '/tag/' . $id, [] );
}

ok( my $response_post = request POST '/tag',
    [   id => 'TeSt',
        description =>
            'Testing porpouses. It can be deleted with no consequences'
    ],
);

ok( $tag_aux = $j->jsonToObj( $response_post->content ) );

my $request_PUT = PUT( '/tag/test', [] );
$request_PUT->header( Accept      => 'application/json' );
$request_PUT->header( description => 'Description edited' );

ok( my $response_PUT = request($request_PUT), 'Delete request' );

my $request_DELETE = DELETE('tag/test');
$request_DELETE->header( Accept => 'application/json' );
ok( my $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

ok( $response_post = request POST '/tag',
    [   id =>
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        description =>
            'Testing porpouses. It can be deleted with no consequences'
    ],
);

ok( $tag_aux = $j->jsonToObj( $response_post->content ) );

ok( $response_post = request POST '/tag',
    [   id => 'test',
        description =>
            'Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences'
    ],
);

ok( $tag_aux = $j->jsonToObj( $response_post->content ) );

ok( $response_post = request POST '/tag',
    [   id => 'no_desc_tag',
        ],
);

is( $response_post->headers->{status}, '201',
    'Response status is 201: Created' );
ok( $tag_aux = $j->jsonToObj( $response_post->content ) );

done_testing();
