package V2::Server::Controller::Event;

use Moose;
use namespace::autoclean;
use Data::Dumper;
use DateTime;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Event - Catalyst Controller

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
    
    if ($event_aux){
	  my @event = $event_aux->hash_event;

	  $c->stash->{content} = \@event;
	  $c->stash->{event} = \@event;
	  $c->response->status(200);
	  $c->stash->{template} = 'event/get_event.tt';    
    }else{
	  my @message = {
		message => "We can't find what you are looking for."
	  };
	  
	  $c->stash->{content} = \@message;
	  $c->stash->{template} = 'old_not_found.tt';
	  $c->response->status(404);
    }


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
    $c->stash->{events} = \@events;
    $c->response->status(200);
    $c->stash->{template} = 'event/get_list.tt';
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

    $c->visit('/check/check_event', [$info, $description]);
    # If all is correct $c->stash->{event_ok} should be 1, otherwise it will be 0.

    if ($c->stash->{event_ok} == 1){
      $new_event->info($info);
      $new_event->description($description);
      $new_event->starts($starts);
      $new_event->ends($ends);
      $new_event->insert;

      my @event = $new_event->hash_event;

      $c->stash->{content} = \@event;
      $c->response->status(201);
      $c->forward( $c->view('JSON') );
    } else {
      my @message = {
	 message => "Error: Check the info and description of the event",
      };
      $c->stash->{content} = \@message;
      $c->response->status(400);
      $c->stash->{error} = "Error: Check the info and description of the event";
      $c->stash->{template} = 'event/get_list';
    }
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("ID: ".$id);
    $c->log->debug("El PUT funciona");

    my $info        = $req->parameters->{info} || $req->query('info');
    my $description = $req->parameters->{description} || $req->query('description');
    my $starts_aux  = $req->parameters->{starts} || $req->query('starts');
    my $starts      = $c->forward('ParseDate',[$starts_aux]);
    my $ends_aux    = $req->parameters->{ends} || $req->query('ends');
    my $ends        = $c->forward('ParseDate',[$req->parameters->{ends}]);

    my $event = $c->model('DB::Event')->find( { id => $id } );

    if ($event) {
         $c->visit('/check/check_event', [$info, $description]);
	 # If all is correct $c->stash->{event_ok} should be 1, otherwise it will be 0.

	 if ($c->stash->{event_ok} == 1){
	    $event->info($info);
	    $event->description($description);
	    $event->starts($starts);
	    $event->ends($ends);
	    $event->insert_or_update;

	    my @event = $event->hash_event;

	    $c->stash->{content} = \@event;
	    $c->response->status(200);
	    $c->forward( $c->view('JSON') );
	 } else {
	         my @message = {
		     message => "Error: Check the info and description of the event",
		  };
		  $c->stash->{content} = \@message;
		  $c->response->status(400);
		  $c->stash->{error} = "Error: Check the info and description of the event";
		  $c->stash->{template} = 'event/get_list';

	 }
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

sub ParseDate :Private {
  my ($self, $c, $date_str) = @_;

  $c->log->debug("Date to parse: ".$date_str);
  
  my ($day,$hour) = split(/T/,$date_str);

  my ($year,$month,$nday) = split(/-/,$day);
  my ($nhour,$min,$sec) = split(/:/,$hour);

  my $date = DateTime->new(year   => $year,
                       month  => $month,
                       day    => $nday,
                       hour   => $nhour,
                       minute => $min,
                       second => $sec,);

  return $date;
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
