package V2::Server::Controller::TagEvent;
use Moose;
use namespace::autoclean;
use Data::Dumper;
use JSON;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::TagEvent - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub default : Local : ActionClass('REST') {
}

sub default_GET {
}

sub default_POST {
}

sub default_PUT {
}

sub default_DELETE {
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut



1;
