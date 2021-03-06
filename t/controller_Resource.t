use strict;
use warnings;
use Test::More;
use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;

BEGIN { require 't/TestingDB.pl' }
BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Resource' }

my $j = JSON::Any->new;

#List of resources ok?
ok( my $response = request GET '/resource', [] );

ok( $response->is_success, 'Request should succeed' );

my $resource_aux = $j->jsonToObj( $response->content );
my @resource = @{$resource_aux};
my $id;

foreach (@resource) {
    $id = $_->{id};
    ok( $response = request GET '/resource/' . $id, [] );
}

=head1
Create new resource
=cut

ok( my $response_post = request POST '/resource',
    [   info        => "Testing resource creation",
        description => ":-P",
    ]
);

ok( $response = request GET '/resource', [] );
$resource_aux = $j->jsonToObj( $response->content );
@resource = @{$resource_aux};
foreach (@resource) {
    $id = $_->{id};
    ok( $response = request GET '/resource/' . $id, [] );
}

=head1
Editing the last created resource
=cut

ok( my $response_put = request PUT '/resource/' . $id,
    [   info        => 'Testing resource edition',
        description => ':-P',
    ]
);

ok( $response = request GET '/resource/' . $id, [] );

my $request_DELETE = DELETE( 'resource/' . $id );
$request_DELETE->header( Accept => 'application/json' );
ok( my $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

done_testing();
