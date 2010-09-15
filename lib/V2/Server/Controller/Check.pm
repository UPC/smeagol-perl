package V2::Server::Controller::Check;

use strict;
use warnings;
use parent 'Catalyst::Controller';

use Data::Dumper;

sub check_name :Local {
 my ($self, $c, $name) = @_;

 if (length($name) < 64 ){
   return 1;
 }else{
    return 0;
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
   return 1;
 }else{
   return 0;
 }
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;