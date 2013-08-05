use strict;
use warnings;
use Test::More;
use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;

BEGIN { require 't/TestingDB.pl' }
BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Root' }

my $j = JSON::Any->new;

my $expected = $V2::Server::DETAILS;

my $response = request( GET '/' );
ok( $response->is_success, 'GET /' );

my $content = $j->jsonToObj( $response->content );
is_deeply( $content, [$expected], 'default content match' );

$response = request( GET '/index' );
ok( $response->is_success, 'GET /index' );

$content = $j->jsonToObj( $response->content );
is_deeply( $content, [$expected], 'index content match' );

$response = request( GET '/version' );
ok( $response->is_success, 'GET /version' );

$content = $j->jsonToObj( $response->content );
is_deeply( $content, $expected, 'version match' );

done_testing();
