package V2::Server::Controller::Tag;

use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::CatalystREST::Controller::tags - Catalyst Controller

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
    my @tag;
    my @tags;

    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );

    my @tag_aux = $c->model('DB::Tag')->all;

#Cal refer el hash que conté els tags perquè treballar directament amb el model de DB::Tag
# és bastant engorrós
    foreach (@tag_aux) {
        @tag = { id => $_->id, };

        push( @tags, @tag );
    }

    if ($id) {
        my $tag;
        foreach (@tags) {
            if ( $_->{id} eq $id ) { $tag = $_; }
        }

        if ( !$tag ) {
            $c->stash->{template} = 'not_found.tt';
            $c->response->status(404);
            $c->forward( $c->view('TT') );
        }
        else {
            $c->stash->{content} = $tag;
            $c->response->status(200);
            $c->forward( $c->view('JSON') );
        }
    }
    else {

        $c->stash->{content} = \@tags;
        $c->response->status(200);
        $c->forward( $c->view('JSON') );
    }

}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $name = $req->parameters->{name};

    my $new_tag = $c->model('DB::Tag')->find_or_new();

    $new_tag->id($name);
    $new_tag->insert;

    my @tag = { id => $new_tag->id, };

    $c->stash->{content} = \@tag;
    $c->response->status(201);
    $c->forward( $c->view('JSON') );
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;

    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

    my $name = $req->parameters->{name};

    my $tag = $c->model('DB::Tag')->find_or_new( { id => $id } );

    if ($tag) {
        $tag->id($name);
        $tag->insert_or_update;

        my @tag = { id => $tag->id, };

        $c->stash->{content} = \@tag;
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

    my $tag_aux = $c->model('DB::Tag')->find( { id => $id } );

    if ($tag_aux) {
        $tag_aux->delete;
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
