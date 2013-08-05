package V2::Server::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in V2/Server.pm

__PACKAGE__->config->{namespace} = '';

=head1 NAME

V2::Server::Controller::Root - Root Controller for V2::Server

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{format} = $c->request->headers->{"accept"} || 'application/json';
}

sub index : Local {
    my ( $self, $c ) = @_;

    $c->stash->{content}  = [ $V2::Server::DETAILS ];
    $c->stash->{template} = 'index.tt';
    $c->response->status(200);
}

sub default : Private {
    # Default is index
    shift->index(@_);
}

sub version : Local {
    my ( $self, $c ) = @_;

    $c->stash->{content} = $V2::Server::DETAILS;
    $c->response->status(200);
}

sub bad_request : Local {
    my ( $self, $c ) = @_;

    $c->stash->{template} = 'bad_request.tt';
    $c->stash->{content}  = [{ status => "400", error  => "Bad request" }];
    $c->response->status(400);
}

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->stash->{format} eq "application/json" ) {
        $c->forward( $c->view('JSON') );
    }
    else {
        $c->stash->{VERSION} = $V2::Server::VERSION;
        $c->forward( $c->view('HTML') );
    }
}

1;
