use strict;
use warnings;
use Test::More;
use JSON::Any;

use Data::Dumper;
use HTTP::Request::Common qw/GET POST PUT DELETE/;

BEGIN { require 't/TestingDB.pl' }
BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Event' }

my $j = JSON::Any->new;

#List of events ok?
ok( my $response = request GET '/event' );

ok( $response->is_success, 'Request should succeed' );

my $event_aux = $j->jsonToObj( $response->content );

my @event = @{$event_aux};
my $id;

foreach (@event) {
    $id = $_->{"id"};
    ok( $response = request GET '/event/' . $id, [] );
    is( $response->headers->{status}, '200', 'Response status is 200: OK' );
}

=head1
Create new event
=cut

ok( my $response_post = request POST '/event',
    [   starts      => '2010-02-16T04:00:00',
        description => ':-P',
        ends        => '2010-02-16T06:00:00',
        info        => 'Estem provant',
        tags        => ''
    ]
);
is( $response_post->headers->{status},
    '201', 'Response status is 201: Created' );

ok( $response = request GET '/event' );
ok( $response->is_success, 'Request should succeed' );
$event_aux = $j->jsonToObj( $response->content );
@event = @{$event_aux};
foreach (@event) {
    $id = $_->{"id"};
    ok( $response = request GET '/event/' . $id, [] );
    is( $response->headers->{status}, '200', 'Response status is 200: OK' );
}

=head1
Editing the last created event
=cut

ok( my $response_put
        = request PUT '/event/' 
        . $id
        . "?starts=2010-02-16T06:00:00&description=:-X&ends=2010-02-16T08:00:00&info='Estem de proves'&tags=edited event,trololo",
    [   starts      => '2010-02-16T06:00:00',
        description => ':-X',
        ends        => '2010-02-16T08:00:00',
        info        => 'Estem provant d\'editar',
        tags        => 'edited event,trololo'
    ]
);

ok( $response_put
        = request PUT '/event/' 
        . '100'
        . "?starts=2010-02-16T06:00:00&description=:-X&ends=2010-02-16T08:00:00&info='Estem de proves'&tags=edited event,trololo",
    [   starts      => '2010-02-16T06:00:00',
        description => ':-X',
        ends        => '2010-02-16T08:00:00',
        info        => 'Estem provant d\'editar',
        tags        => 'edited event,trololo'
    ]
);

is( $response_put->headers->{status}, '404',
    'Response status is 404: Not found' );

my $request_DELETE = DELETE( 'event/' . $id );
$request_DELETE->header( Accept => 'application/json' );
ok( my $response_DELETE = request($request_DELETE), 'Delete request' );
is( $response_DELETE->headers->{status}, '200',
    'Response status is 200: OK' );

done_testing();
