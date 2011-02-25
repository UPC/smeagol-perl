use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Event' }

my $j = JSON::Any->new;

#List of events ok?
ok( request('/event')->is_success, 'Request should succeed' );

ok( my $response = request GET '/event' );

diag '###################################';
diag '##Requesting events one by one##';
diag '###################################';

my $event_aux = $j->jsonToObj( $response->content );

my @event = @{$event_aux};
my $id;

foreach (@event) {
    $id = $_->{"id"};
    ok( $response = request GET '/event/' . $id, [] );
    is( $response->headers->{status}, '200', 'Response status is 200: OK');
}

=head1
Create new event
=cut

diag '#########Creating event#########';
diag '###################################';

ok( my $response_post = request POST '/event',
    [   starts      => '2010-02-16T04:00:00',
        description => ':-P',
        ends        => '2010-02-16T06:00:00',
        info        => 'Estem provant',
        tags        => 'test,prova'
    ]
);
is( $response_post->headers->{status}, '201', 'Response status is 201: Created');

$event_aux = $j->from_json( $response_post->content );
my $eid = $event_aux->{id};

=head1
Editing the last created event
=cut

diag '##########Editing event#########';
diag '###################################';

diag "Editing event " . $eid;

#diag "ID: ".$id;
ok( my $response_put
        = request PUT '/event/' 
        . $eid
        . "?starts=2010-02-16T06:00:00&description=:-X&ends=2010-02-16T08:00:00&info='Estem de proves'&tags=edited event,trololo",
    [   starts      => '2010-02-16T06:00:00',
        description => ':-X',
        ends        => '2010-02-16T08:00:00',
        info        => 'Estem provant d\'editar',
        tags        => 'edited event,trololo'
    ]
);
diag $response_put->content;

diag '#########Deleting event#########';
diag '###################################';

my $request_DELETE = DELETE( 'event/'.$eid);
$request_DELETE->header( Accept => 'application/json' );
ok(my $response_DELETE = request($request_DELETE), 'Delete request');
is( $response_DELETE->headers->{status}, '200', 'Response status is 200: OK');

my $request_DELETE = DELETE( 'tag/edited event');
$request_DELETE->header( Accept => 'application/json' );
ok($response_DELETE = request($request_DELETE), 'Delete request first tag');

my $request_DELETE = DELETE( 'tag/trololo');
$request_DELETE->header( Accept => 'application/json' );
ok($response_DELETE = request($request_DELETE), 'Delete request second tag');

my $request_DELETE = DELETE( 'tag/test');
$request_DELETE->header( Accept => 'application/json' );
ok($response_DELETE = request($request_DELETE), 'Delete request third tag');

done_testing();
