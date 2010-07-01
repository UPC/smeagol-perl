package V2::Server::Controller::Event;

use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Event - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index

=cut

sub default : Local : ActionClass('REST') {
}

sub default_GET {
    my ( $self, $c, $res, $id ) = @_;

    if ($id) {
        $c->forward( 'get_event', [$id] );
    }
    else {
        $c->forward( 'event_list', [] );
    }
}

sub get_event : Local {
    my ( $self, $c, $id ) = @_;

    my $event_aux = $c->model('DB::Event')->find( { id => $id } );

    my @event = $event_aux->hash_event;

    $c->stash->{content} = \@event;
    $c->response->status(200);
    $c->forward( $c->view('JSON') );
}

sub event_list : Local {
    my ( $self, $c, $id ) = @_;

    my @events_aux = $c->model('DB::Event')->all;
    my @event;
    my @events;

    foreach (@events_aux) {
        @event = $_->hash_event;

        push( @events, @event );
    }

    $c->stash->{content} = \@events;
    $c->response->status(200);
    $c->forward( $c->view('JSON') );
}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $info        = $req->parameters->{info};
    my $description = $req->parameters->{description};
    my $starts      = $req->parameters->{starts};
    my $ends        = $req->parameters->{ends};

    my $new_event = $c->model('DB::Event')->find_or_new();

    $new_event->info($info);
    $new_event->description($description);
    $new_event->starts($starts);
    $new_event->ends($ends);
    $new_event->insert;

    my @event = $new_event->hash_event;

    $c->stash->{content} = \@event;
    $c->response->status(201);
    $c->forward( $c->view('JSON') );
}

sub default_PUT {
    my ( $self, $c, $id ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

    my $info        = $req->parameters->{info};
    my $description = $req->parameters->{description};
    my $starts      = $req->parameters->{starts};
    my $ends        = $req->parameters->{ends};

    my $event = $c->model('DB::Event')->find( { id => $id } );

    if ($event) {
        $event->info($info);
        $event->description($description);
        $event->starts($starts);
        $event->ends($ends);
        $event->insert_or_update;

        my @event = $event->hash_event;

        $c->stash->{content} = \@event;
        $c->response->status(200);
        $c->forward( $c->view('JSON') );
    }
    else {
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
        $c->forward( $c->view('TT') );
    }
}

sub default_DELETE {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;

    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El DELETE funciona");

    my $event_aux = $c->model('DB::Event')->find( { id => $id } );

    if ($event_aux) {
        $event_aux->delete;
        $c->stash->{template} = 'event/delete_ok.tt';
        $c->response->status(200);
        $c->forward( $c->view('TT') );
    }
    else {
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
        $c->forward( $c->view('TT') );
    }
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
