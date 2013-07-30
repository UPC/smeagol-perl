package V2::Server::Controller::Event;

use Moose;
use namespace::autoclean;
use DateTime;
use Encode qw(encode decode);
my $enc     = 'utf-8';
BEGIN { extends 'Catalyst::Controller::REST' }


=head1 NAME

V2::Server::Controller::Event - Catalyst Controller

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
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;
	my @message;

    if ($id) {
		if((defined $module)&&($module eq 'tag')) {
			if($id_module){
		    	$c->detach( 'get_relation_tag_event', [$id, $id_module]);
			}else{
				$c->response->location($c->uri_for('/tag')."/?event=".$id);
				#TODO: message: redireccio a la llista
				$c->stash->{content}  = \@message;
				$c->response->status(301);
			}
		}else{
		    $c->detach( 'get_event', [$id] );
		}
    }
    else {
        $c->detach( 'event_list', [] );
    }
}

sub get_relation_tag_event : Private {
    my ( $self, $c, $id , $id_module) = @_;
    my $event = $c->model('DB::TEvent')->find( { id => $id } );
    my @message;

    if ( !$event ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {

        $c->detach( '/tag/get_tag_from_object', [ $id, $c->namespace, $id_module ] );
    }
}
sub get_event : Local {
    my ( $self, $c, $id ) = @_;
    my $event_aux = $c->model('DB::TEvent')->find( { id => $id } );
    
    if ($event_aux) {
        my $event = {
            id          => $event_aux->id,
            info        => decode( $enc, $event_aux->info ),
            description => decode( $enc, $event_aux->description ),
            starts      => $event_aux->starts->iso8601(),
            ends        => $event_aux->ends->iso8601(),
        };
	
	#TODO: message: Esdeveniment llistat amb èxit. 
        $c->stash->{content} = $event;
        $c->stash->{event}   = $event;
        $c->response->status(200);
        $c->stash->{template} = 'event/get_event.tt';
    }
    else {
        my @message;
       
	#TODO: message: Esdeveniment no trobat.
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }

}

sub event_list : Local {
    my ( $self, $c, $id ) = @_;

    my @events_aux = $c->model('DB::TEvent')->all;
    my @event;
    my @events;

    foreach (@events_aux) {
        @event = $_->hash_event;

        push( @events, @event );
    }
    
    #TODO: llistat d'esdeveniments generat amb èxit 
    $c->stash->{content} = \@events;
    $c->stash->{events}  = \@events;
    $c->response->status(200);
    $c->stash->{template} = 'event/get_list.tt';
}

sub default_POST {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;
    my $req = $c->request;
    my @message;
 
    if((defined $module) &&($module eq 'tag')){
		$c->detach( 'post_relation_tag_event');
	}

    my $info        = $req->parameters->{info};
    my $description = $req->parameters->{description};
    my $starts      = $req->parameters->{starts};
    my $ends        = $req->parameters->{ends};

    my $new_event = $c->model('DB::TEvent')->find_or_new();
    my $tag_event;

    #Checking the info, description and dates format.
    $c->visit( '/check/check_event', [ $info, $description, $starts, $ends ] );
    
    
    
# If all is correct $c->stash->{event_ok} should be 1, otherwise it will be 0.

    if ( $c->stash->{event_ok} == 1 ) {
        $new_event->info($info);
        $new_event->description($description);
        $new_event->starts($starts);
        $new_event->ends($ends);
        $new_event->insert;

        my $tags;
        my $id_tag;
=pod
        foreach (@tags) {
            $id_tag = $_;

            $tags = $c->model('DB::TTag')->find( { id => $id_tag } );

            if ($tags) {
                $tag_event = $c->model('DB::TTagEvent')->find_or_new();
                $tag_event->id_tag($id_tag);
                $tag_event->id_event( $new_event->id );
                $tag_event->insert;
            }
            else {
                $c->detach( '/bad_request', [] );
            }
        }
=cut
        my $event = {
            id          => $new_event->id,
            info        => decode( $enc, $new_event->info ),
            description => decode( $enc, $new_event->description ),
            starts      => $new_event->starts->iso8601(),
            ends        => $new_event->ends->iso8601(),
#            tags        => $new_event->tag_list,
            bookings    => $new_event->booking_list
        };

        #TODO: message: Esdeveniment creat amb exit.
        $c->stash->{content}  = \@message;
        $c->response->status(201);
        $c->response->location($req->uri->as_string."/".$new_event->id);
		$c->forward( $c->view('JSON') );
    }
    else {
	
	#TODO: message: Verifiqui el info, descripció i dates de l'esdeveniment
        my @message;
        $c->stash->{content} = \@message;
        $c->response->status(400);
        $c->stash->{error}
            = "Error: Check the info and description of the event";
        $c->stash->{template} = 'event/get_list.tt';
    }
}

sub post_relation_tag_event : Private {
    my ( $self, $c) = @_;
    my @message;
    
	#TODO: message: operacio no permesa 
	$c->stash->{content} = \@message; 
    $c->response->status(405);
}

sub default_PUT {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;

    if ($id) {
		if((defined $module) && ($module eq 'tag') && ($id_module)){
		    $c->forward( 'put_relation_tag_event', [$id, $id_module]);
		}else{
		    $c->forward( 'put_event', [$id] );
		}
    }
}

sub put_event : Private {
    my ( $self, $c, $id ) = @_;
    my $req = $c->request;

    my $info        = $req->parameters->{info};
    my $description = $req->parameters->{description};
    my $starts_check = $req->parameters->{starts};
    my $ends_check = $req->parameters->{ends};
    
    my $starts_aux = $req->parameters->{starts};
    my $starts = $c->forward( 'ParseDate', [$starts_aux] );

    my $ends_aux = $req->parameters->{ends};
    my $ends = $c->forward( 'ParseDate', [$ends_aux] );

    my @tags;
	if (defined $req->parameters->{tags}) {@tags = split( ',', $req->parameters->{tags} );}

    my $event = $c->model('DB::TEvent')->find( { id => $id } );
    my $tag_event;
    
    #Checking the info, description and dates format.
    if ($event) {
        $c->visit( '/check/check_event', [ $info, $description, $starts_check, $ends_check ] );


# If all is correct $c->stash->{event_ok} should be 1, otherwise it will be 0.

        if ( $c->stash->{event_ok} == 1 ) {
            $event->info($info);
            $event->description($description);
            $event->starts($starts);
            $event->ends($ends);
            $event->insert_or_update;

            my $tags;

            my @tag_event_aux = $c->model('DB::TTagEvent')
                ->search( { id_event => $event->id } );

            foreach (@tag_event_aux) {
                $_->delete;
            }

            my $id_tag;
            foreach (@tags) {
                $id_tag = $_;

                $tags = $c->model('DB::TTag')->find( { id => $id_tag } );

                if ($tags) {
                    $tag_event = $c->model('DB::TTagEvent')->find_or_new();
                    $tag_event->id_tag($id_tag);
                    $tag_event->id_event( $event->id );
                    $tag_event->insert;
                }
                else {
                    $c->detach( '/bad_request', [] );
                }
            }

            my $event = {
                id          => $event->id,
                info        => decode( $enc, $event->info ),
                description => decode( $enc, $event->description ),
                starts      => $event->starts->iso8601(),
                ends        => $event->ends->iso8601(),
                tags        => $event->tag_list,
                bookings    => $event->booking_list
            };
	    
	    #TODO: message: Esdeveniment actualitzat amb èxit.
            my @message;
            $c->stash->{content} = \@message;
            $c->response->status(200);
            $c->forward( $c->view('JSON') );
        }
        else {
	    
	    #TODO: message: Verifiqui el info, descripció i dates de l'esdeveniment
            my @message;
            $c->stash->{content} = \@message;
            $c->response->status(400);
            $c->stash->{error}
                = "Error: Check the info and description of the event";
            $c->stash->{template} = 'event/get_list.tt';

        }
    }
    else {
	
	#TODO: message: Esdeveniment no trobat.
        my @message; 
        $c->stash->{content} = \@message;
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
    }
}

sub put_relation_tag_event : Private {
    my ( $self, $c, $id_event , $id_module) = @_;
    my $event = $c->model('DB::TEvent')->find( { id => $id_event } );
    my @message;

    if ( !$event ) {
		#TODO: message: Event no trobat.
        $c->stash->{content}  = \@message;
        $c->response->status(404);
    }
    else {
        $c->detach( '/tag/put_tag_object', [ $id_event, $c->namespace, $id_module ] );
    }
}

sub default_DELETE {
    my ( $self, $c, $res, $id, $module, $id_module) = @_;
    
    my $req = $c->request;
    
if ($id) {
    if((defined $module) && ($module eq 'tag') && ($id_module)){
        $c->detach( 'delete_relation_tag_event', [$id, $id_module]);
    }
    else {
        my $event_aux = $c->model('DB::TEvent')->find( { id => $id } );
        my @message;
        if ($event_aux) {
	    $event_aux->delete;
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
}
}

sub delete_relation_tag_event : Private {
    my ( $self, $c, $id , $id_module) = @_;
    my $event = $c->model('DB::TEvent')->find( { id => $id } );
    my @message;

    if ( !$event ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        $c->detach( '/tag/delete_tag_from_object', [ $id, $c->namespace, $id_module ] );
    }
}


=head2 ParseDate
Outrage!! The author is repeting himself. Throw him to the fire!!
=cut

sub ParseDate : Private {
    my ( $self, $c, $date_str ) = @_;


    my ( $day, $hour ) = split( /T/, $date_str );

    my ( $year, $month, $nday ) = split( /-/, $day );
    my ( $nhour, $min ) = split( /:/, $hour );

    my $date = DateTime->new(
        year   => $year,
        month  => $month,
        day    => $nday,
        hour   => $nhour,
        minute => $min,
    );

    return $date;
}

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->stash->{format} ne "application/json" ) {
        $c->stash->{VERSION} = $V2::Server::VERSION;
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

