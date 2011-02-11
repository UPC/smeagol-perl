package V2::Server::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

my $name    = 'Smeagol Server';
my $version = '2.0';

=head1 NAME

V2::CatalystREST::Controller::Root - Root Controller for V2::CatalystREST

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{format} = $c->request->headers->{"accept"}
        || 'application/json';
}

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->response->status(200);
    $c->stash->{template} = 'index.tt';
    $c->forward( $c->view('HTML') );
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->status(404);
    $c->stash->{template} = 'old_not_found.tt';
}

sub version : Local {
    my ( $self, $c ) = @_;

    $c->response->status(200);

    my @message = {
        application => $name,
        version     => $version
    };
    $c->stash->{content} = \@message;
}

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->stash->{format} ne "application/json" ) {
        $c->forward( $c->view('HTML') );
    }
    else {
        $c->forward( $c->view('JSON') );
    }
}

=head1 AUTHOR

Jordi Amorós Andreu

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
