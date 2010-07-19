use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok 'Catalyst::Test', 'V2::Server';
    use_ok 'DBICx::TestDatabase';
}

ok my ( $res, $c ) = ctx_request('/'),
    'context object';    # make sure we got the context object...

my $schema        = DBICx::TestDatabase->new('V2::Server::Schema');
my @resources_aux = $c->model('DB::Resource')->all;

my @resources;
my @resource;
foreach (@resources_aux) {
    @resource = {
        id          => $_->id,
        info        => $_->info,
        description => $_->description,
    };
    push( @resources, @resource );

}

diag( Dumper( \@resources ) );

diag("############################################################## \n");
diag("Create resource \n");
diag("############################################################## \n");

ok my $new_resource = $c->model('DB::Resource')->find_or_new();

ok $new_resource->info('Test');
ok $new_resource->description('Test resource');
ok( $new_resource->insert, 'Resource creation should succeed' );

my $id_new = $new_resource->id;
diag( "New Resource ID: " . $id_new );

unless ( my $resource_edit
    = $c->model('DB::Resource')->find( { id => $id_new } ) )
{
    diag("Resource created failed");
}
else {
    diag("Resource creation ok");
}

diag("############################################################## \n");
diag(" Edition resource \n");
diag("############################################################## \n");
my $resource_edit = $c->model('DB::Resource')->find( { id => $id_new } );
ok $resource_edit->info('Test (edited)');
ok $resource_edit->description('Test resource (edited)');
ok( $resource_edit->update, 'resource edition should succeed' );

diag("############################################################## \n");
diag(" Checking resource edition \n");
diag("############################################################## \n");

my $resource_check = $c->model('DB::Resource')->find( { id => $id_new } );

diag( "\nId resource: " . $resource_check->id . " and should be " . $id_new );
diag("There is something wrong") unless $resource_check->id eq $id_new;

diag(     "\nresource info: "
        . $resource_check->info
        . " and should be "
        . 'Test (edited)' );
diag("Info edition failed") unless $resource_check->info eq 'Test (edited)';

diag(     "\nresource info: "
        . $resource_check->description
        . " and should be "
        . 'Test resource (edited)' );
diag("Description edition failed")
    unless $resource_check->description eq 'Test resource (edited)';

diag("############################################################## \n");
diag(" Delete resource edition \n");
diag("############################################################## \n");

$resource_check->delete;

unless ( my $resource_check
    = $c->model('DB::Resource')->find( { id => $id_new } ) )
{
    diag("Delete test ok \n");
}
else {
    diag("Delete test failed \n");
}

done_testing();

