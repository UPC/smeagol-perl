use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Resource' }

my $j = JSON::Any->new;

#List of resources ok?
ok( request('/resource')->is_success, 'Request should succeed' );

ok(my $response = request GET '/resource', []);

diag 'Resource list: '.$response->content;
diag '###################################';
diag '##Requesting resources one by one##';
diag '###################################';
my $resource_aux = $j->jsonToObj($response->content);

my @resource = @{$resource_aux};
my $id;

foreach (@resource) {
  $id = $_->{"id"};
  ok($response = request GET '/resource/'.$id, []);
  diag 'Resource '.$id.' '.$response->content;
  diag '###################################';
}

=head1
Create new resource
=cut

diag '#########Creating resource#########';
diag '###################################';

ok(my $response_post = request POST '/resource', [info=>'Testing resource creation', description=>':-P', tags=>'test,delete me']);
diag $response_post->content;

=head1
Editing the last created resource
=cut

diag '##########Editing resource#########';
diag '###################################';
$resource_aux = $j->decode($response_post->content);
@resource = @{$resource_aux};
diag Dumper(@resource);
#$id = @resource->{"id"};

#diag "ID: ".$id;
ok(my $response_put = request PUT '/resource/20', [info=>'Testing resource edition', description=>':-P', tags=>'test,edited']);
diag $response_put->content;

diag '#########Deleting resource#########';
diag '###################################';
ok($response = request GET '/resource', []);
my $resource_aux = $j->jsonToObj($response->content);

my @resource = @{$resource_aux};
my $id;

my $ua = LWP::UserAgent->new;
my $request_del = HTTP::Request->new(DELETE => 'http://localhost:3000/resource/1');
foreach (@resource) {
  $id = $_->{"id"};
  $request_del = HTTP::Request->new(DELETE => 'http://localhost:3000/resource/'.$id);
  ok($ua->request($request_del));
}

done_testing();
