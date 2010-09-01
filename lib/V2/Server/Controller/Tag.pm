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

    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );

    if ($id) {
        $c->forward( 'get_tag', [$id] );
    }
    else {
        $c->forward( 'tag_list', [] );
    }
}

sub get_tag :Private {
  my ($self, $c, $id) = @_;

  my $tag = $c->model('DB::Tag')->find({id=>$id});

  if ( !$tag ) {
      $c->stash->{template} = 'old_not_found.tt';
      $c->response->status(404);
  }
  else {
      my @tag = {
	  id          => $tag->id,
	  description => $tag->description,
      };
    
      $c->stash->{tag} = $tag;
      $c->stash->{content} = \@tag;
      $c->response->status(200);
      $c->stash->{template} = 'tag/get_tag.tt';
  }
}

sub tag_list :Private {
  my ($self, $c) = @_;
  my @tag;
  my @tags;
  
  my @tag_aux = $c->model('DB::Tag')->all;

    foreach (@tag_aux) {
        @tag = {
            id          => $_->id,
            description => $_->description,
        };

        push( @tags, @tag );
    }

  $c->stash->{tags} = \@tags;
  $c->stash->{content} = \@tags;
  $c->stash->{template} = 'tag/get_list.tt';
}


sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $name = $req->parameters->{name};
    my $desc = $req->parameters->{description};

    my $new_tag = $c->model('DB::Tag')->find_or_new();

    $new_tag->id($name);
    $new_tag->description($desc);
    $new_tag->insert;

    my @tag = {
        id          => $new_tag->id,
        description => $new_tag->description
    };

    $c->stash->{tag}      = \@tag;
    $c->stash->{content} = \@tag;
    $c->stash->{template} = 'tag/get_tag.tt';
    $c->response->content_type('text/html');
    $c->response->redirect('tag/'.$new_tag->id);
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;

    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

    my $name = $req->parameters->{name};
    my $desc = $req->parameters->{description};

    my $tag = $c->model('DB::Tag')->find( { id => $id } );

    if ($tag) {
        $tag->id($name);
	$tag->description($desc);
        $tag->insert_or_update;

        my @tag = { id => $tag->id, description => $tag->description};

        $c->stash->{tag} = \@tag;
	$c->stash->{content} = \@tag;
        $c->response->status(200);
    }
    else {
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
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
	$c->response->content_type('text/html');
	$c->forward( 'tag_list', [] );
    }
    else {
        $c->stash->{template} = 'not_found.tt';
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
