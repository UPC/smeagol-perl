package V2::Server::Controller::Check;

use Moose;
use namespace::autoclean;
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::SpanSet; 
use DateTime::Event::ICal;

BEGIN { extends 'Catalyst::Controller::REST' }

=head2 check_name check_desc check_info
This function are used to verify that the parameter name has a lenght within 
the correct length range.
=cut

sub check_name :Local {
 my ($self, $c, $name) = @_;

 if (length($name) < 64 ){
   $c->stash->{name_ok}=1;
 }else{
    $c->stash->{name_ok}=0;
 }

}

sub check_desc :Local {
 my ($self, $c, $desc) = @_;

  if (length($desc) < 128 ){
    $c->log->debug("Descr OK");
   $c->stash->{desc_ok}=1;
 }else{
   $c->log->debug("Descr KO");
   $c->stash->{desc_ok}=0;
 }
}

sub check_info :Local {
 my ($self, $c, $info) = @_;

  if (length($info) < 256 ){
   $c->stash->{info_ok}=1;
 }else{
   $c->stash->{info_ok}=0;
 }
}

=head2 check_booking
We verify that the resource exists and that the booking will be associated with an existing event.
If one of these two conditions isn't not fullfiled, the booking can't be made.
=cut

sub check_booking : Local {
  my ($self, $c) = @_;
  my $id_resource = $c->stash->{id_resource};
  my $id_event = $c->stash->{id_event};

  $c->log->debug("Check booking. ID resource: ".$id_resource);
  $c->log->debug("Check booking. ID event: ".$id_event);
  
  my $resource = $c->model('DB::Resources')->find({id => $id_resource});
  my $event = $c->model('DB::Event')->find({id => $id_event});

  if ($resource && $event) {
    $c->stash->{booking_ok}=1;
  } else {
    $c->stash->{booking_ok}=0;
  }

}

=head2 check_event
Function used to verify that event parameters are within the proper range 
=cut

sub check_event : Local {
  my ($self, $c, $info, $description) = @_;

  $c->visit('check_info', [$info]);
  $c->visit('check_desc', [$description]);

  if ($c->stash->{info_ok} && $c->stash->{desc_ok}) {
    $c->stash->{event_ok} = 1;
  }else{
    $c->stash->{event_ok} = 0;
  }
}

=head2 check_resource
Function used to verify that resource parameters are within the proper range 
=cut

sub check_resource :Local {
  my ($self, $c, $info, $description) = @_;

  $c->visit('check_info', [$info]);
  $c->visit('check_desc', [$description]);

  if ($c->stash->{info_ok} && $c->stash->{desc_ok}) {
    $c->stash->{resource_ok} = 1;
  }else{
    $c->stash->{resource_ok} = 0;
  }
}

=head2 check_overlap
With the parameters from the current request we build firstly a DateTime::Event::Ical and secondly
using the duration parameter we obtain $spanSet (a DateTime::SpanSet which we can check if it
intersecs with the existing ones).

Once we have $spanSet, the process previously explained is repeated for each one of the existing
bookings of the resource. If there isn't any overlap: OK. If there is overlap the booking will not
be inserted in the DB.
=cut

sub check_overlap :Local {
  my ($self, $c) = @_;
  
  my $new_booking = $c->stash->{new_booking};
  
  $c->log->debug("Provant si hi ha solapament");
  $c->stash->{overlap} = 0;
  $c->stash->{empty} = 0;
  
  my @byday = split(',',$new_booking->by_day);
  my @bymonth = split(',',$new_booking->by_month);
  my @bymonthday = split(',',$new_booking->by_day_month);
  
  #$c->log->debug("DTSTART (pre-ICAL): ".Dumper($new_booking->dtstart));
  $c->log->debug("DTEND (pre-ICAL): ".Dumper($new_booking->dtend->iso8601()));
  $c->log->debug("UNTIL (pre-ICAL): ".Dumper($new_booking->until->iso8601()));
  
  my $current_set = DateTime::Event::ICal->recur(
    dtstart => $new_booking->dtstart,
    dtend => $new_booking->dtend,
    until => $new_booking->until,
    freq => $new_booking->frequency,
    interval => $new_booking->interval,
    byminute => $new_booking->by_minute,
    byhour => $new_booking->by_hour,
    byday => \@byday,
    bymonth => \@bymonth,
    bymonthday => \@bymonthday
  );
  
  $c->log->debug(Dumper($current_set));
if ($current_set->min) {
  $c->log->debug("L'SpanSet té com a mínim un element");
  $c->stash->{empty} = 0;
}else{
  $c->log->debug("L'SpanSet està buit!");
  $c->stash->{empty} = 1;
}
  
  my $duration = DateTime::Duration->new(
    minutes => $new_booking->duration,
  );
  
  $c->log->debug("Duració nova reserva:
  ".$duration->hours."h".$duration->minutes."min");
  
  my $spanSet = DateTime::SpanSet->from_set_and_duration(
    set      => $current_set,
    duration => $duration
  );
  
  my $old_set;
  my $spanSet2;
  my $duration2;
  my $overlap;
  my @booking_aux;
  if ($c->stash->{PUT}){
    @booking_aux = $c->model('DB::Booking')->search({id_resource=>
    $new_booking->id_resource->id})->search({ id => {'!=' => $new_booking->id}
})->search({until=>{'>' => $new_booking->dtstart } });
    
  }else{  
    @booking_aux = $c->model('DB::Booking')->search({id_resource=>
$new_booking->id_resource->id});    
  }

  $c->log->debug("Hi ha ".@booking_aux." que compleixen els criteris de la cerca");
  
  foreach (@booking_aux) {
    $c->log->debug("Checking Booking #".$_->id);
    @byday = split(',',$_->by_day);
    @bymonth = split(',',$_->by_month);
    @bymonthday = split(',',$_->by_day_month);
    $old_set = DateTime::Event::ICal->recur(
      dtstart => $_->dtstart,
      until => $_->until,
      freq =>    $_->frequency,
      interval => $_->interval,
      byminute => $_->by_minute,
      byhour => $_->by_hour,
      byday => \@byday,
      bymonth => \@bymonth,
      bymonthday => \@bymonthday
    );
    
    $duration2 = DateTime::Duration->new(
      minutes => $_->duration
    );
    $spanSet2 = DateTime::SpanSet->from_set_and_duration(
      set      => $old_set,
      duration => $duration2
    );
    
    $overlap = $spanSet->intersects( $spanSet2 );
    
    if ($overlap) {
      $c->stash->{overlap} = 1;
      last;
    }
  }
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
