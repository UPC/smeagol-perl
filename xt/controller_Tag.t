use strict;
use warnings;
use Test::More;
use JSON::Any;

use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Tag' }

my $j = JSON::Any->new;

#Request list of bookings
diag '#############################################';
diag '###########Requesting tag\'s list ###########';
diag '#############################################';

ok( my $response = request GET '/tag',
    HTTP::Headers->new( Accept => 'application/json' ) );

diag "Llista de tags: " . $response->content;

ok( request('/tag')->is_success, 'Request should succeed' );

diag '#################################################';
diag '###########Requesting tags one by one ###########';
diag '#################################################';

ok( my $tag_aux = $j->jsonToObj( $response->content ) );

my @tag = @{$tag_aux};
my $id;

foreach (@tag) {
    $id = $_->{id};
    ok( $response = request GET '/tag/' . $id, [] );
    diag 'Tag ' . $id . ' ' . $response->content;
    diag '###################################';
}

diag '###################################';
diag '###########Creating tag ###########';
diag '###################################';

ok( my $response_post = request POST '/tag',
    [   id => 'TeSt',
        description =>
            'Testing porpouses. It can be deleted with no consequences'
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Nou tag: " . $response_post->content;

ok( $tag_aux = $j->jsonToObj( $response_post->content ) );

diag '###################################';
diag '###########Editing tag ###########';
diag '###################################';
my $request_PUT = PUT('/tag/test', []);
$request_PUT->header( Accept => 'application/json' );
$request_PUT->header( description => 'Description edited' );

ok(my $response_PUT = request($request_PUT), 'Delete request');

diag "Edited tag: " . $response_PUT->content;

diag '###################################';
diag '###########Deleting tag ###########';
diag '###################################';
my $request_DELETE = DELETE( 'tag/test');
$request_DELETE->header( Accept => 'application/json' );
ok(my $response_DELETE = request($request_DELETE), 'Delete request');
is( $response_DELETE->headers->{status}, '200', 'Response status is 200: OK');

diag '###########################################';
diag '##Creating tag with invalid id (too long)##';
diag '###########################################';

ok( $response_post = request POST '/tag',
    [   id => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        description =>
            'Testing porpouses. It can be deleted with no consequences'
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Nou tag: " . $response_post->content;

ok( $tag_aux = $j->jsonToObj( $response_post->content ) );

diag '####################################';
diag '##Creating tag with invalid desc ##';
diag '###################################';

ok( $response_post = request POST '/tag',
    [   id => 'test',
        description =>
            'Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences. Testing porpouses. It can be deleted with no consequences'
    ],
    HTTP::Headers->new( Accept => 'application/json' )
);

diag "Nou tag: " . $response_post->content;

ok( $tag_aux = $j->jsonToObj( $response_post->content ) );


done_testing();
