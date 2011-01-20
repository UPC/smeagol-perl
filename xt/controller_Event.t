use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Event' }

my $j = JSON::Any->new;

#List of events ok?
#ok( request('/event')->is_success, 'Request should succeed' );

ok( my $response = request GET '/event' );
# 
# diag 'Resource list: ' . $response->content;
# diag '###################################';
# diag '##Requesting events one by one##';
# diag '###################################';
my $event_aux = $j->jsonToObj( $response->content );
# 
# my @event = @{$event_aux};
# my $id;
# 
# foreach (@event) {
#     $id = $_->{"id"};
#     ok( $response = request GET '/event/' . $id, [] );
#     diag 'Resource ' . $id . ' ' . $response->content;
#     diag '###################################';
# }

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
	tags => 'test,prova'
    ]
);
diag $response_post->content;

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
        = request PUT '/event/'.$eid."?starts=2010-02-16T06:00:00&description=:-X&ends=2010-02-16T08:00:00&info='Estem de proves'&tags=edited event,trololo",
    [   starts      => '2010-02-16T06:00:00',
        description => ':-X',
        ends        => '2010-02-16T08:00:00',
        info        => 'Estem provant d\'editar',
	tags => 'edited event,trololo'
    ]
);
diag $response_put->content;

diag '#########Deleting event#########';
diag '###################################';

my $ua = LWP::UserAgent->new;
my $request_del
    = HTTP::Request->new( DELETE => 'http://localhost:3000/event/' . $eid );
my $response_del;
diag $request_del->content;
ok($response_del = $ua->request($request_del) );
diag $response_del->content;


my $ua_del      = LWP::UserAgent->new;

$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/tag/test');
$request_del->header(Accept => 'application/json');
ok($response_del = $ua_del->request($request_del) );

$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/tag/prova');
$request_del->header(Accept => 'application/json');
ok($response_del = $ua_del->request($request_del) );

$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/tag/trololo');
$request_del->header(Accept => 'application/json');
ok($response_del = $ua_del->request($request_del) );

$request_del = HTTP::Request->new( DELETE => 'http://localhost:3000/tag/edited event');
$request_del->header(Accept => 'application/json');
ok($response_del = $ua_del->request($request_del) );

done_testing();
