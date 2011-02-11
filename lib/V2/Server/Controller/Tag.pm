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

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{format} = $c->request->headers->{"accept"}
        || 'application/json';
}

sub default : Local : ActionClass('REST') {
}

sub default_GET {
    my ( $self, $c, $res, $id ) = @_;

    if ($id) {
        $c->detach( 'get_tag', [$id] );
    }
    else {
        $c->detach( 'tag_list', [] );
    }
}

sub tag_list : Private {
    my ( $self, $c ) = @_;
    my @tag;
    my @tags;
    my @message;

    my @tag_aux = $c->model('DB::TTag')->all;

    foreach (@tag_aux) {
        @tag = {
            id          => $_->id,
            description => $_->description,
        };

        push( @tags, @tag );
    }

    $c->stash->{content}  = \@tags;
    $c->stash->{tags}     = \@tags;
    $c->stash->{template} = 'tag/get_list.tt';

}

sub get_tag : Private {
    my ( $self, $c, $id ) = @_;
    my @message;
    my $tag = $c->model('DB::TTag')->find( { id => $id } );

    if ( !$tag ) {
        @message = { message => "We can't find what you are looking for." };

        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        my @resource_tag
            = $c->model('DB::TResourceTag')->search( { tag_id => $id } );

        my @resources;
        my $resource_aux;
        my @resource;

        foreach (@resource_tag) {
            $resource_aux = $c->model('DB::TResource')
                ->find( { id => $_->resource_id } );
            @resource = $resource_aux->get_resources;
            push( @resources, @resource );
        }

        my $tag = {
            id          => $tag->id,
            description => $tag->description,
            resources   => \@resources
        };

        $c->stash->{content} = $tag;
        $c->stash->{tag_aux} = $tag;
        $c->response->status(200);
        $c->stash->{template} = 'tag/get_tag.tt';
    }

}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    my @new_tag;

    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $id   = $req->parameters->{id};
    my $desc = $req->parameters->{description};

    $c->visit( '/check/check_name', [$id] );
    $c->visit( '/check/check_desc', [$desc] );

    my $tag_exist = $c->model('DB::TTag')->find( { id => $id } );

    if ( !$tag_exist ) {    #Creation of the new tag if it not exists
        my $new_tag = $c->model('DB::TTag')->find_or_new();

        if ( ( $c->stash->{name_ok} and $c->stash->{desc_ok} ) != 0
            and length($id) > 1 )
        {
            $new_tag->id($id);
            $new_tag->description($desc);
            $new_tag->insert;

            $new_tag = {
                id          => $id,
                description => $desc
            };

            $c->stash->{content}  = $new_tag;
            $c->stash->{tag}      = $new_tag;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->content_type('text/html');
            $c->response->status(201);
        }
        else {

            my @message
                = { message =>
                    'There\'s a problem with the id of the tag or the description is too long'
                };

            $new_tag = {
                id          => $id,
                description => $desc
            };

            $c->stash->{content}  = @message;
            $c->stash->{tag}      = $new_tag;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->content_type('text/html');
            $c->stash->{error}
                = 'There\'s a problem with the id of the tag or the description is too long';
            $c->response->status(400);
        }

    }
    else {    # The tag exists, therefore the server informs of the fact
        @new_tag = {
            id          => $tag_exist->id,
            description => $tag_exist->description
        };

        $c->stash->{content}  = \@new_tag;
        $c->stash->{tag}      = \@new_tag;
        $c->stash->{template} = 'tag/get_tag.tt';
        $c->response->content_type('text/html');
        $c->stash->{error} = 'This tag already exists';
        $c->response->status(409);
    }
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;
    my @message;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

    my $desc = $req->parameters->{description}
        || $req->{headers}->{description};

    my $tag = $c->model('DB::TTag')->find( { id => $id } );

    $c->visit( '/check/check_name', [$id] );
    $c->visit( '/check/check_desc', [$desc] );

    $c->log->debug( "Desc OK? " . $c->stash->{desc_ok} );
    if ($tag) {
        if ( ( $c->stash->{name_ok} and $c->stash->{desc_ok} ) != 0
            and length($id) > 1 )
        {
            $tag->id($id);
            $tag->description($desc);
            $tag->insert_or_update;

            my $tag = {
                id          => $tag->id,
                description => $tag->description
            };

            $c->stash->{content}  = $tag;
            $c->stash->{tag}      = $tag;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->status(200);
        }
        else {
            my @message
                = { message =>
                    'There\'s a problem with the id of the tag or the description is too long.'
                };

            my $new_tag = {
                id          => $id,
                description => $desc
            };

            $c->stash->{content}  = \@message;
            $c->stash->{tag}      = $new_tag;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->content_type('text/html');
            $c->stash->{error}
                = 'There\'s problem with the id of the tag or the description is too long.';
            $c->response->status(400);

        }
    }
    else {
        @message = { message => "We can't find what you are looking for." };

        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
}

sub default_DELETE {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;
    my @message;

    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El DELETE funciona");

    my $tag_aux = $c->model('DB::TTag')->find( { id => $id } );
    my @resource_tag
        = $c->model('DB::TResourceTag')->search( { tag_id => $id } );

    if ($tag_aux) {
        $tag_aux->delete;

        foreach (@resource_tag) {
            $_->delete;
        }

        @message = { message => "Tag succesfully deleted" };
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'tag/delete_ok.tt';
        $c->response->status(200);
    }
    else {

        @message = { message => "We can't find what you are looking for." };

        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }

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

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
