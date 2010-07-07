package V2::Server::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

V2::CatalystREST::Controller::Root - Root Controller for V2::CatalystREST

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->redirect( $c->uri_for('/resource') );
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->status(404);
    $c->stash->{template} = 'not_found.tt';
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
  my ( $self, $c ) = @_;
  $c->component('View::JSON')->encoding('utf-8');
}

=head1 AUTHOR

Jordi Amorós Andreu

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
