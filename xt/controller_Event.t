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

diag 'Resource list: ' . $response->content;
diag '###################################';
diag '##Requesting events one by one##';
diag '###################################';
my $event_aux = $j->jsonToObj( $response->content );

my @event = @{$event_aux};
my $id;

foreach (@event) {
    $id = $_->{"id"};
    ok( $response = request GET '/event/' . $id, [] );
    diag 'Resource ' . $id . ' ' . $response->content;
    diag '###################################';
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
        info        => 'Estem provant'
    ]
);
diag $response_post->content;

$event_aux= $j->from_json( $response_post->content );
@event = @{$event_aux};
my $eid;

foreach (@event){
      $eid = $_->{id};
}

=head1
Editing the last created event
=cut

diag '##########Editing event#########';
diag '###################################';


diag "Editing event " . $eid;

#diag "ID: ".$id;
ok( my $response_put = request PUT '/event/'.$eid."?starts=2010-02-16T06:00:00&description=:-X&ends=2010-02-16T08:00:00&info='Estem de proves'",
    [   starts      => '2010-02-16T06:00:00',
        description => ':-X',
        ends        => '2010-02-16T08:00:00',
        info        => 'Estem provant d\'editar'
    ]
);
diag $response_put->content;

diag '#########Deleting event#########';
diag '###################################';

my $ua = LWP::UserAgent->new;
my $request_del
    = HTTP::Request->new( DELETE => 'http://localhost:3000/event/' . $eid );
diag $request_del->content;
ok( my $response_del = $ua->request($request_del) );
diag $response_del->content;

done_testing();
