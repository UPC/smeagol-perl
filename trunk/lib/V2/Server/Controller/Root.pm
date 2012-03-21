package V2::Server::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

my $name = 'Smeagol Server';

my $VERSION = $V2::Server::VERSION;

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

sub index :Local {
    my ( $self, $c ) = @_;
    $c->response->status(200);
    $c->stash->{template} = 'index.tt';
    my @message = {
        application => $name,
        version     => $VERSION
    };
    $c->stash->{content} = \@message;

}

sub default : Private {
     my ( $self, $c ) = @_;
     $c->response->status(200);
     $c->stash->{template} = 'index.tt';
     my @message = {
	  application => $name,
	  version     => $VERSION
     };
     $c->stash->{content} = \@message;
}

sub version : Local {
    my ( $self, $c ) = @_;

    $c->response->status(200);

    my $message = {
        application => $name,
        version     => $VERSION
    };
    $c->stash->{content} = $message;
}

sub bad_request : Local {
    my ( $self, $c ) = @_;

    $c->response->status(400);
    $c->stash->{template} = 'bad_request.tt';
    my @message = {
        status => "400",
        error  => "Bad request"
    };

    $c->stash->{content} = \@message;
}

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->stash->{format} ne "application/json" ) {
        $c->stash->{VERSION} = $VERSION;
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
