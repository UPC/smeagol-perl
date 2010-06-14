use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok 'Catalyst::Test', 'V2::Server'; 
    use_ok 'DBICx::TestDatabase';
}

ok my ($res, $c) = ctx_request('/'), 'context object';  # make sure we got the context object...

my $schema = DBICx::TestDatabase->new('V2::Server::Schema');
my @bookings_aux = $c->model('DB::Booking')->all;

diag ("Bookings un per un");

my @bookings;
my @booking;
foreach (@bookings_aux) {
      @booking = {
	    id => $_->id,
	    id_resource => $_->id_resource->id,
	    id_event => $_->id_event->id,
	    starts => $_->starts->iso8601(),
	    ends => $_->ends->iso8601()
      };
      push (@bookings, @booking);
      $c->log->_send_to_log("Booking: ".$_->id."\n");
      $c->log->_send_to_log("ID REcurs: ".$_->id_resource->id."\n");
      $c->log->_send_to_log("ID Event: ".$_->id_event->id."\n");
      $c->log->_send_to_log("Starts: ".$_->starts->iso8601()."\n");
      $c->log->_send_to_log("Ends: ".$_->ends->iso8601()."\n");
      $c->log->_send_to_log("-----------------------------------------------------------------------------"."\n");
}

diag ("Llista de reserves: \n");
diag (Dumper(@bookings));

diag ("Crear booking \n");
my $new_booking = $c->model('DB::Booking')->find_or_new();
my $id_resource = 1;
my $id_event = 1;
my $starts = '2010-06-16T05:00:00';
my $ends = '2010-06-16T07:00:00';

$new_booking->id_resource($id_resource);
$new_booking->id_event($id_event);
$new_booking->starts($starts);
$new_booking->ends($ends);  

=head2
Ara mateix, en V2::Server::Schema::Booking el mètode overlap sempre retorna 1
per tant la reserva no s'escriurà
=cut

my $overlap = $new_booking->overlap;

if ($overlap){
      diag("Hi ha solapament, no s'afegirà la reserva");
}else{
      $new_booking->insert;
      diag("La reserva s'ha desat correctament");
}

$new_booking->insert;

diag("ID de la reserva nova: ".$new_booking->id);

my $id_test = $new_booking->id;

=head2
Editem un recurs, el desem. Tornem a demanar el recurs editat i comprovem 
que les dades estan com toca
=cut
diag("Editar reserves \n");
my $edited_booking = $c->model('DB::Booking')->find({id=>$id_test});

$edited_booking->id_resource('2');
$edited_booking->id_event('3');
$edited_booking->starts('2010-06-16T05:00:00');
$edited_booking->ends('2010-06-16T07:00:00');  
$edited_booking->update;

my $check_booking = $c->model('DB::Booking')->find({id=>$id_test});

diag("\nId resource is: ".$check_booking->id_resource->id." and should be 2");
diag("id_resource edition failed") unless $check_booking->id_resource->id eq '2';

diag("\nId event is: ".$check_booking->id_event->id." and should be 3");
diag("id_event edition failed") unless $check_booking->id_event->id eq '3';

diag("\nstarts is: ".$check_booking->starts->iso8601()." and should be 2010-06-16T07:00:00"); 
diag("starts edition failed") unless $check_booking->starts->iso8601() eq '2010-06-16T05:00:00';

diag("\nends is: ".$check_booking->ends->iso8601()." and should be 2010-06-16T05:00:00");
diag("ends edition failed") unless $check_booking->ends->iso8601() eq '2010-06-16T07:00:00';

=head2
=cut
diag("Esborra reserves \n");

  $check_booking->delete;

  unless (my $check_booking2 = $c->model('DB::Booking')->find({id=>$id_test})) {
    diag("Delete test ok \n");
  }else{
    diag("Delete test failed \n");
  }

done_testing();
