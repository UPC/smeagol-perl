package V2::Server::Controller::Check;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Data::Dumper;

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

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;