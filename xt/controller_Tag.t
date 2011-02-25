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
    [   id => 'test',
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

my $ua_put      = LWP::UserAgent->new;
my $request_put = HTTP::Request->new(
    PUT => 'http://localhost:3000/tag/test',
    [ description => 'Edited' ]
);

$request_put->header( Accept => 'application/json' );

diag "PUT request: " . Dumper($request_put) . "\n";

my $response_put;
ok( $response_put = $ua_put->request($request_put) );
diag "Edited tag: " . $response_put->content;

diag '###################################';
diag '###########Deleting tag ###########';
diag '###################################';
my $ua_del = LWP::UserAgent->new;
my $request_del
    = HTTP::Request->new( DELETE => 'http://localhost:3000/tag/test' );
$request_del->header( Accept => 'application/json' );
ok( my $response_del = $ua_del->request($request_del) );
diag $response_del->content;

done_testing();
