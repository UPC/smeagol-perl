package V2::Server::Controller::Check;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Data::Dumper;
use DateTime::Event::ICal;

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

sub check_booking : Local {
  my ($self, $c, $id_resource, $id_event) = @_;

  my $resource = $c->model('DB::Resource')->find({id => $id_resource});
  my $event = $c->model('DB::Event')->find({id => $id_event});

  if ($resource && $event) {
    $c->stash->{booking_ok}=1;
  } else {
    $c->stash->{booking_ok}=0;
  }
}

sub check_overlap :Local {
  my ($self, $c, $new_booking) = @_;
  
  my $new_set = DateTime::Event::ICal->recur(
      dtstart => $new_booking->dtstart,
      dtend => $new_booking->dtend,
      freq => $new_booking->frequency,
      interval => $new_booking->interval,
      byhour =>  $new_booking->by_hour,
      byminute => $new_booking->by_minute
      
      );

  $c->stash->{overlap}=0;
}

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

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
