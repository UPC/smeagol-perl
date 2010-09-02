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

my $schema     = DBICx::TestDatabase->new('V2::Server::Schema');
my @events_aux = $c->model('DB::Event')->all;

my @events;
my @event;
foreach (@events_aux) {
    @event = {
        id          => $_->id,
        info        => $_->info,
        description => $_->description,
        starts      => $_->starts->iso8601(),
        ends        => $_->ends->iso8601(),
    };
    push( @events, @event );

}

diag( Dumper( \@events ) );

diag("############################################################## \n");
diag("Crear event \n");
diag("############################################################## \n");

ok my $new_event = $c->model('DB::Event')->find_or_new();

ok $new_event->info('Test');
ok $new_event->description('Test event');
ok $new_event->starts('2010-06-16T05:00:00');
ok $new_event->ends('2010-06-16T06:00:00');
ok( $new_event->insert, 'Event creation should succeed' );

my $id_new = $new_event->id;
diag( "New Event ID: " . $id_new );

unless ( my $event_edit = $c->model('DB::Event')->find( { id => $id_new } ) )
{
    diag("Event created failed");
}
else {
    diag("Event creation ok");
}

diag("############################################################## \n");
diag(" Edition event \n");
diag("############################################################## \n");
my $event_edit = $c->model('DB::Event')->find( { id => $id_new } );
ok $event_edit->info('Test (edited)');
ok $event_edit->description('Test event (edited)');
ok $event_edit->starts('2010-07-16T05:00:00');
ok $event_edit->ends('2010-07-16T06:00:00');
ok( $event_edit->update, 'Event edition should succeed' );

diag("############################################################## \n");
diag(" Checking event edition \n");
diag("############################################################## \n");

my $event_check = $c->model('DB::Event')->find( { id => $id_new } );

diag( "\nId event: " . $event_check->id . " and should be " . $id_new );
diag("There is something wrong") unless $event_check->id eq $id_new;

diag(     "\nEvent info: "
        . $event_check->info
        . " and should be "
        . 'Test (edited)' );
diag("Info edition failed") unless $event_check->info eq 'Test (edited)';

diag(     "\nEvent info: "
        . $event_check->description
        . " and should be "
        . 'Test event (edited)' );
diag("Description edition failed")
    unless $event_check->description eq 'Test event (edited)';

diag("############################################################## \n");
diag(" Delete event edition \n");
diag("############################################################## \n");

$event_check->delete;

unless ( my $event_check = $c->model('DB::Event')->find( { id => $id_new } ) )
{
    diag("Delete test ok \n");
}
else {
    diag("Delete test failed \n");
}

done_testing();
