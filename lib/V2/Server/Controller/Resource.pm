package V2::Server::Controller::Resource;

use Moose;
use namespace::autoclean;
use Data::Dumper;

use Encode qw(encode decode);
my $enc     = 'utf-8';
my $VERSION = $V2::Server::VERSION;
BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::CatalystREST::Controller::resource - Catalyst Controller

=head1 name

Catalyst Controller.

=head1 METHODS

=cut

=head2 default

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{format} = $c->request->headers->{"accept"}
        || 'application/json';

}

sub default : Path : ActionClass('REST') {
}

sub default_GET {
    my ( $self, $c, $id, $module, $id_module ) = @_;

    if ($id) {
	if(($module eq 'tag') && ($id_module)){
	    $c->forward( 'get_relation_tag_resource', [$id, $id_module]);
	}else{
	    $c->forward( 'get_resource', [$id] );
	}
    }
    else {
        $c->forward( 'resource_list', [] );
    }
}

sub get_relation_tag_resource : Private {
    my ( $self, $c, $id , $id_module) = @_;
    my $resource = $c->model('DB::TResource')->find( { id => $id } );
    my @message;

    if ( !$resource ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        $c->detach( '/tag/get_tag_from_object', [ $id, 'resource', $id_module ] );
    }
}

sub get_resource : Private {
    my ( $self, $c, $id ) = @_;
    my $resource = $c->model('DB::TResource')->find( { id => $id } );
	my @message;

    if ( !$resource ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        my $res = {
            id          => $resource->id,
            description => decode( $enc, $resource->description ),
            info        => decode( $enc, $resource->info ),
        };

        $c->stash->{resource} = $res;
        $c->stash->{content}  = $res;
        $c->response->status(200);
        $c->stash->{template} = 'resource/get_resource.tt';
    }
}

sub resource_list : Private {
    my ( $self, $c ) = @_;
    my @resources;
    my @res_aux = $c->model('DB::TResource')->all;

    foreach (@res_aux) {
        push( @resources, $_->get_resources );

    }

    $c->stash->{resources} = \@resources;
    $c->stash->{content}   = \@resources;
    $c->response->status(200);
    $c->stash->{template} = 'resource/get_list.tt';
}

sub default_POST {
    my ( $self, $c, $id ) = @_;
    my $req = $c->request;
    my @message;

    my $descr = $req->parameters->{description};
    my $info  = $req->parameters->{info};

    $c->visit( '/check/check_resource', [ $info, $descr ] );

# If all is correct $c->stash->{event_ok} should be 1, otherwise it will be 0.

    my @resource_exist
        = $c->model('DB::TResource')->search( { description => $descr } );

    if ( @resource_exist > 0 ) {
        $c->stash->{resource_ok} = 0;
        $c->stash->{conflict}    = 1;
    }

    if ( $c->stash->{resource_ok} ) {

        my $new_resource = $c->model('DB::TResource')->find_or_new();

        $new_resource->description($descr);
        $new_resource->info($info);
        $new_resource->insert;

#Un cop tenim el tema dels tags aclarit, muntem el json amb les dades del recurs
        my $resource = {
            id          => $new_resource->id,
            description => decode( $enc, $new_resource->description ),
            info        => decode( $enc, $new_resource->info ),
        };

		#TODO: message: Resource creat amb exit.
        $c->stash->{resource} = $resource;
        $c->stash->{content}  = \@message;
		$c->response->status(201);
        $c->response->content_type('text/html');
        $c->response->header(
            'Location' => $c->uri_for( $c->action, $new_resource->id ) );
        $c->stash->{template} = 'resource/get_resource.tt';
    }
    else {
        if ( $c->stash->{conflict} ) {
            #TODO: message: Descripcio ja en us
			$c->stash->{content} = \@message;
            $c->response->status(409);
            $c->stash->{error}
                = "Error: A resource with the same description already exist";
            $c->response->content_type('text/html');
            $c->stash->{template} = 'resource/get_list.tt';
        }
        else {
            $c->stash->{content} = \@message;
            $c->response->status(400);
            $c->stash->{error}
                = "Error: Check the info and description of the resource";
            $c->response->content_type('text/html');
            $c->stash->{template} = 'resource/get_list.tt';
        }
    }
}

sub default_PUT {
    my ( $self, $c, $id ) = @_;
    my $req = $c->request;
    my @message;

    my $descr = $req->parameters->{description};
    my $info     = $req->parameters->{info};

    my $resource = $c->model('DB::TResource')->find( { id => $id } );

    if ($resource) {
        $c->visit( '/check/check_resource', [ $info, $descr ] );
        my @resource_exist
            = $c->model('DB::TResource')->search( { description => $descr } );

        if ( @resource_exist > 0 ) {
            $c->stash->{resource_ok} = 0;
            $c->stash->{conflict}    = 1;
        }

# If all is correct $c->stash->{event_ok} should be 1, otherwise it will be 0.
        if ( $c->stash->{resource_ok} ) {
            $resource->description($descr);
            $resource->info($info);
            $resource->update;

            my @resource = {
                id          => $resource->id,
                description => decode( $enc, $resource->description ),
                info        => decode( $enc, $resource->info ),
            };

			#TODO: message: Resource actualitzat amb èxit.
            $c->stash->{resource} = \@resource;
            $c->stash->{content}  = \@message;
            $c->response->status(200);
        }
        else {
            if ( $c->stash->{conflict} ) {
                #TODO: message: Descripcio ja en us
                $c->stash->{content} = \@message;
                $c->response->status(409);
                $c->stash->{error}
                    = "Error: A resource with the same description already exist";
                $c->response->content_type('text/html');
                $c->stash->{template} = 'resource/get_list.tt';
            }
            else {
				#TODO: message: Descripcio o info incorrectes
                $c->stash->{content} = \@message;
                $c->response->status(400);
                $c->stash->{error}
                    = "Error: Check the info and description of the resource";
                $c->response->content_type('text/html');
                $c->stash->{template} = 'resource/get_list.tt';
            }
        }
    }
    else {
       	#TODO: message: Resource no trobat.
        $c->stash->{content} = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->content_type('text/html');
        $c->response->status(404);
    }

}

sub default_DELETE {
    my ( $self, $c, $id ) = @_;
    my $req = $c->request;

    my $resource_aux = $c->model('DB::TResource')->find( { id => $id } );
	my @message;

    if ($resource_aux) {

        $resource_aux->delete;

		#TODO: message: Resource esborrat amb èxit.
        $c->stash->{content}  = \@message;
    }
    else {

		#TODO: message: Resource no trobat.
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

Jordi Amorós Andreu

=cut

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
