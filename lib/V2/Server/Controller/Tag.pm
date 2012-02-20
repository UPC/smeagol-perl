package V2::Server::Controller::Tag;

use Moose;
use namespace::autoclean;
use V2::Server::Obj::Tag;
use Exception::Class::TryCatch;
use Encode qw(encode decode);
my $enc     = 'utf-8';
my $VERSION = $V2::Server::VERSION;
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
    my $req = $c->request;
    my @tag;
    my @tags;
    my @message;

    my @tag_aux = $c->model('DB::TTag')->all;

    foreach (@tag_aux) {
        @tag = {
            id          => decode( $enc, $_->id ),
            description => decode( $enc, $_->description ),
            location => decode( $enc, $c->response->location($req->uri->as_string."/".$_->id) ),
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

    $id = decode( $enc, $id );
    $id = lc $id;
    $id = encode( $enc, $id );

    my $tag = $c->model('DB::TTag')->find( { id => $id } );

    if ( !$tag ) {
        #@message = { message => "We can't find what you are looking for." };
        
        #TODO: message: tag not found
        $c->stash->{content}  = \@message;
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
 # FIXME: aixo es obligacio del V2::Server::Schema::Result::Tag
        my $tag = {
            id          => decode( $enc, $tag->id ),
            description => decode( $enc, $tag->description ),
        };

        $c->stash->{content} = $tag;
        $c->stash->{tag_aux} = $tag;
        $c->response->status(200);
        $c->stash->{template} = 'tag/get_tag.tt';
    }

}


sub get_tag_from_object : Private {
    my ( $self, $c, $id , $module ,  $id_module) = @_;
    my $tag = $c->model('DB::TTag')->find( { id => $id_module } );
    my @message;

    if ( !$tag ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        my $object = $c->model('DB::TResourceTag')->find( { tag_id => $id_module, resource_id => $id } ) if ($module eq 'resource');
	$object = $c->model('DB::TTagEvent')->find( { id_tag => $id_module, id_event => $id } ) if ($module eq 'event');
	$object = $c->model('DB::TTagBooking')->find( { id_tag => $id_module, id_booking => $id } ) if ($module eq 'booking');
	if ( !$object ) {
	    	#TODO: message: Relacio no trobada.
	    $c->stash->{content}  = \@message;
	    $c->response->status(404);
	}else{
	    #TODO: message: Relacio trobada.
	    $c->stash->{content}  = \@message;
	    $c->response->status(200);
	}
    }
}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    my @new_tag;
    my @message;
=head2
decode($enc, $str); 
$text_str = lc $text_str; 
$text_str = encode($enc, $text_str);
=cut

    my $id = decode( $enc, $req->parameters->{id} );
    $id = lc $id;
    $id = encode( $enc, $id );
    my $desc = $req->parameters->{description}
        || $req->{headers}->{description};

my $tag_ok;
my $err;

if($req->parameters->{description} || $req->{headers}->{description}){	
    $tag_ok = try
        eval { new V2::Server::Obj::Tag( id => $id, description => $desc ) };
    catch $err;
  
}else{
    $tag_ok = try
        eval { new V2::Server::Obj::Tag( id => $id ) };
    catch $err;
}

    my $tag_exist = $c->model('DB::TTag')->find( { id => $id } );

    if ( !$tag_exist ) {    #Creation of the new tag if it not exists
        my $new_tag = $c->model('DB::TTag')->find_or_new();

        if ($tag_ok) {
            $new_tag->id($id);
            $new_tag->description($desc);
            $new_tag->insert;

            $new_tag = {
                id          => decode( $enc, $id ),
                description => decode( $enc, $desc )
            };
           
            
            #TODO: message: tag creat amb exit.
            $c->stash->{content}  = \@message;
            $c->stash->{tag}      = $new_tag;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->status(201);
 	    $c->response->location($req->uri->as_string."/".$id);

        }
        else {
            my ($error) = split( "\n", $err->message );
            ($error) = split( 'at', $error );
            
           #TODO: message: tag no se ha pogut crear.                     
            $c->stash->{content}  = \@message;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->content_type('text/html');
            $c->stash->{error}
                = 'There\'s a problem with the id of the tag or the description is too long';
            $c->response->status(400);
        }

    }
    else {    
        # The tag exists, therefore the server informs of the fact
        @new_tag = {
            id          => $tag_exist->id,
            description => $tag_exist->description
        };
       
       
        
        #TODO: message: tag ja existeix.
        $c->stash->{content}  = \@message;
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

    $id = decode( $enc, $id );
    $id = lc $id;
    $id = encode( $enc, $id );

    my $desc = $req->parameters->{description}
        || $req->{headers}->{description};

    my $tag_ok = try
        eval { new V2::Server::Obj::Tag( id => $id, description => $desc ) };
    catch my $err;


    my $tag = $c->model('DB::TTag')->find( { id => $id } );
  

    if ($tag) {
        if ($tag_ok) {
            $tag->id($id);
            $tag->description($desc);
            $tag->insert_or_update;

            my $tag = {
                id          => decode( $enc, $tag->id ),
                description => decode( $enc, $tag->description )
            };    

            #TODO: message: tag creat correctament
            $c->stash->{content}  = \@message;
            $c->stash->{tag}      = $tag;
            $c->stash->{template} = 'tag/get_tag.tt';
            $c->response->status(200);
        }
        else {
            my ($error) = split( "\n", $err->message );
            ($error) = split( 'at', $error );

            my @message = { message => $error };
           
            

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
       
        #TODO: message: tag deletead
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
}

sub default_DELETE {
    my ( $self, $c, $res, $id ) = @_;

    $id = decode( $enc, $id );
    $id = lc $id;
    $id = encode( $enc, $id );

    my $req = $c->request;
    my @message;

  
    my $tag_aux = $c->model('DB::TTag')->find( { id => $id } );
    my @resource_tag
        = $c->model('DB::TResourceTag')->search( { tag_id => $id } );

    if ($tag_aux) {
        $tag_aux->delete;

        foreach (@resource_tag) {
            $_->delete;
        }
        #TODO: message: tag eliminat correctament    
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'tag/delete_ok.tt';
        $c->response->status(200);
    }
    else {

      
        #TODO: message: tag deleted
        $c->stash->{content}  = \@message;
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }

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

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
