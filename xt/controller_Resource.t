use strict;
use warnings;
use Test::More;
use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Resource' }

my $j = JSON::Any->new;

#List of resources ok?
ok( request('/resource')->is_success, 'Request should succeed' );

ok( my $response = request GET '/resource', [] );

diag '###################################';
diag '##Requesting resources one by one##';
diag '###################################';
my $resource_aux = $j->jsonToObj( $response->content );

my @resource = @{$resource_aux};
my $id;

foreach (@resource) {
    $id = $_->{id};
    ok( $response = request GET '/resource/' . $id, [] );
    diag 'Resource ' . $id . ' ' . $response->content;
    diag '###################################';
}

=head1
Create new resource
=cut

diag '#########Creating resource#########';
diag '###################################';

ok( my $response_post = request POST '/resource',
    [   info        => "Testing resource creation",
        description => ":-P",
        tags        => "test,delete me"
    ]
);
diag $response_post->content;

=head1
Editing the last created resource
=cut

diag '##########Editing resource#########';
diag '###################################';
$resource_aux = $j->decode( $response_post->content );

$id = $resource_aux->{id};

diag "Last resource created ID: " . $id;

ok( my $response_put = request PUT '/resource/' . $id,
    [   info        => 'Testing resource edition',
        description => ':-P',
        tags        => 'test,edited'
    ]
);

ok( $response = request GET '/resource/' . $id, [] );
diag 'Edited Resource ' . $id . ' ' . $response->content;

diag '#########Deleting resource#########';
diag '###################################';
my $request_DELETE = DELETE( 'resource/' . $id );
$request_DELETE->header( Accept => 'application/json' );
ok( my $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

done_testing();
