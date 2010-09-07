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

sub begin :Private {
      my ($self, $c) = @_;

      $c->stash->{format} = $c->request->headers->{"accept"} || 'application/json';
}

sub default : Local : ActionClass('REST') {
}

sub default_GET {
    my ( $self, $c, $res, $id ) = @_;
    my @tag;
    my @tags;
    my @message;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );

    my @tag_aux = $c->model('DB::Tag')->all;

#Cal refer el hash que conté els tags perquè treballar directament amb el model de DB::Tag
# és bastant engorrós
    foreach (@tag_aux) {
        @tag = {
            id          => $_->id,
            description => $_->description,
        };

        push( @tags, @tag );
    }

    if ($id) {
        my $tag;
        foreach (@tags) {
            if ( $_->{id} eq $id ) { $tag = $_; }
        }

        if ( !$tag ) {
	  @message = {
	    message => "We can't find what you are looking for."
	  };

	  $c->stash->{content} = \@message;
	  $c->stash->{template} = 'old_not_found.tt';
	  $c->response->status(404);
        }else{
	  $c->stash->{content} = $tag;
	  $c->stash->{tag} = $tag;
	  $c->response->status(200);
	  $c->stash->{template} = 'tag/get_tag.tt';
        }
    }
    else {
	$c->stash->{content} = \@tags;
        $c->stash->{tags}     = \@tags;
        $c->stash->{template} = 'tag/get_list.tt';
    }

}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    my @new_tag;
    
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $name = $req->parameters->{name};
    my $desc = $req->parameters->{description};

    my $tag_exist = $c->model('DB::Tag')->find({id=>$name});
    
    if (!$tag_exist){
      my $new_tag = $c->model('DB::Tag')->find_or_new();

      $new_tag->id($name);
      $new_tag->description($desc);
      $new_tag->insert;

      @new_tag = {
	id => $name,
	description => $desc
      };
      
      $c->stash->{content} = \@new_tag;
      $c->stash->{tag}      = $new_tag;
      $c->stash->{template} = 'tag/get_tag.tt';
      $c->response->content_type('text/html');
      $c->response->status(201);
    } else {

      @new_tag = {
	id => $tag_exist->id,
	description => $tag_exist->description
      };
      
      $c->stash->{content} = \@new_tag;
      $c->stash->{tag}      = $tag_exist;
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

    my $name = $id;
    my $desc = $req->parameters->{description};
    
    my $tag = $c->model('DB::Tag')->find( { id => $id } );

    if ($tag) {
        $tag->id($name);
	$tag->description($desc);
        $tag->insert_or_update;

        my @tag = {
	  id => $tag->id,
	  description => $tag->description
	};

        $c->stash->{content} = \@tag;
	$c->stash->{tag} = $tag;
	$c->stash->{template} = 'tag/get_tag.tt';
	$c->response->content_type('text/html');
        $c->response->status(200);
    }
    else {
	@message = {
	  message => "We can't find what you are looking for."
	};

	$c->stash->{content} = \@message;
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

    my $tag_aux = $c->model('DB::Tag')->find( { id => $id } );

    if ($tag_aux) {
        $tag_aux->delete;

	@message = {
	  message => "Tag succesfully deleted"
	};
	$c->stash->{content} = \@message;
        $c->stash->{template} = 'tag/delete_ok.tt';
        $c->response->status(200);
    }
    else {

	@message = {
	  message => "We can't find what you are looking for."
	};

	$c->stash->{content} = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }

}

sub end :Private {
      my ($self,$c)= @_;

      if ($c->stash->{format} ne "application/json") {
	    $c->forward( $c->view('HTML') );
      }else{
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
