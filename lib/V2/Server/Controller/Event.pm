package V2::Server::Controller::Event;

use Moose;
use namespace::autoclean;
use Data::Dumper;
use JSON;

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

sub default_GET  {
  my ( $self, $c, $res, $id ) = @_;
  my $j = JSON->new;

  if ($id){
    my $event_aux = $c->model('DB::Event')->find({id=>$id});

    my @event = {
	    id=>$event_aux->id,
	    info=>$event_aux->info,
	    description=>$event_aux->description,
	    starts=>$event_aux->starts->iso8601(),
	    ends=>$event_aux->ends->iso8601(),
	  };

    my $jevent = $j->encode(\@event);
    $c->log->debug($jevent);
    $c->stash->{event}=$jevent;
    $c->stash->{template}='event/get_event.tt';
    $c->forward( $c->view('TT') );

  }else{
    my @events_aux = $c->model('DB::Event')->all;
    my @event;
    my @events;
    foreach (@events_aux){
      @event = {
	id=>$_->id,
	info=>$_->info,
	description=>$_->description,
	starts=>$_->starts->iso8601(),
	ends=>$_->ends->iso8601(),
      };
  push (@events, @event);
}

$c->log->debug("#Events: ".@events);


    my $jevents = $j->encode(\@events);
    $c->log->debug($jevents);
    $c->stash->{events}=$jevents;
    $c->stash->{template}='event/get_list.tt';
    $c->forward( $c->view('TT') );
  }
}

sub default_POST {
      my ($self, $c) = @_;
      my $req=$c->request;
      $c->log->debug('Mètode: '.$req->method);
      $c->log->debug ("El POST funciona");
      my $j = JSON->new;

      my $info=$req->parameters->{info};
      my $description=$req->parameters->{description};
      
      my $new_event = $c->model('DB::Event')->find_or_new();
      
      $new_event->info($info);
      $new_event->description($description);
      $new_event->insert;
      
      my @event = {
	    id => $new_event->id,
	    info => $new_event->info,
	    description => $new_event->description,
	    starts => $new_event->starts,
	    ends => $new_event->ends,
      };
      
      $c->stash->{event}=$j->encode(\@event);
      $c-> stash-> {template} = 'event/get_event.tt';
      $c->forward( $c->view('TT') );
}

sub default_PUT {
      my ($self, $c, $id) = @_;
      my $req=$c->request;
      $c->log->debug('Mètode: '.$req->method);
      $c->log->debug ("El POST funciona");
      my $j = JSON->new;

      my $info=$req->parameters->{info};
      my $description=$req->parameters->{description};
      
      my $event = $c->model('DB::Event')->find({id=>$id});

      if ($event){
	$event->info($info);
	$event->description($description);
	$event->insert_or_update;

	my @event = {
	      id => $event->id,
	      info => $event->info,
	      description => $event->description,
	      starts => $event->starts,
	      ends => $event->ends,
	};
	
	$c->stash->{event}=$j->encode(\@event);
	$c-> stash-> {template} = 'event/get_event.tt';
	$c->forward( $c->view('TT') );
      }else{
	$c-> stash-> {template} = 'not_found.tt';
	$c->forward( $c->view('TT') );
      }
}

sub default_DELETE {
      my ($self, $c, $res, $id) = @_;
      my $req=$c->request;
      
      $c->log->debug('Mètode: '.$req->method);	
      $c->log->debug ("El DELETE funciona");
      
      my $event_aux = $c->model('DB::Event')->find({id=>$id});
      
      if ($event_aux){
	    $event_aux-> delete;
	    $c-> stash-> {template} = 'event/delete_ok.tt';
	    $c->forward( $c->view('TT') );
      }else{
	    $c-> stash-> {template} = 'not_found.tt';
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
