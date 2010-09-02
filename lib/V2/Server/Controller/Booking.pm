package V2::Server::Controller::Booking;

use Moose;
use namespace::autoclean;
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Span;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Booking_P - Catalyst Controller

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
        $c->detach( 'get_booking', [$id] );
    }
    else {
        $c->detach( 'booking_list', [] );
    }
}

sub get_booking : Private {
    my ( $self, $c, $id ) = @_;

    my $booking_aux = $c->model('DB::Booking')->find( { id => $id } );

    if ($booking_aux) {
        my @booking = $booking_aux->hash_booking;

        $c->stash->{content} = \@booking;
	$c->stash->{booking} = \@booking;
        $c->response->status(200);
	$c->stash->{template} = 'booking/get_booking.tt';

    }
    else {
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
}

sub booking_list : Private {
    my ( $self, $c ) = @_;

    my @booking_aux = $c->model('DB::Booking')->all;
    my @booking;
    my @bookings;

    foreach (@booking_aux) {
        @booking = $_->hash_booking;
        push( @bookings, @booking );
    }

    $c->stash->{content} = \@bookings;
    $c->stash->{bookings} = \@bookings;
    $c->response->status(200);
    $c->stash->{template} = 'booking/get_list.tt';

}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    #$c->log->debug(Dumper($req));
    $c->log->debug("El POST funciona");

    my $id_resource = $req->parameters->{id_resource} || $req->query('id_resource');
    my $id_event    = $req->parameters->{id_event} || $req->query('id_event');
    my $starts      = $req->parameters->{starts} || $req->query('starts');
    my $ends        = $req->parameters->{ends} || $req->query('ends');

    my $new_booking = $c->model('DB::Booking')->find_or_new();

    $new_booking->id_resource($id_resource);
    $new_booking->id_event($id_event);
    $new_booking->starts($starts);
    $new_booking->ends($ends);

    my @old_bookings
        = $c->model('DB::Booking')->search( { id_resource => $id_resource } )
        ;    #Recuperem les reserves que utilitzen el recurs
    $c->log->debug( "Ends: " . $new_booking->ends );
    my $current_set = DateTime::Span->from_datetimes(
        start => $new_booking->starts,
        end   => $new_booking->ends
    );

    my $overlap;

    foreach (@old_bookings) {
        $overlap = $_->overlap($current_set);
        if ($overlap) {
            last;
        }
    }

    if ($overlap) {
        $c->log->debug("Hi ha solapament \n");
        $c->stash->{template} = 'fail.tt';
        $c->response->status(404);
	$c->response->content_type('text/html');
        $c->forward( $c->view('TT') );
    }
    else {
        $new_booking->insert;

        my @booking = $new_booking->hash_booking;

        $c->stash->{content}  = \@booking;
        $c->response->status(201);
        $c->forward( $c->view('JSON') );

    }
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

#$c->log->debug(Dumper($req->headers));
    
    my $id_resource = $req->parameters->{id_resource} || $req->query('id_resource');
    my $id_event    = $req->parameters->{id_event} || $req->query('id_event');
    my $starts_aux  = $req->parameters->{starts} || $req->query('starts');
    my $ends_aux    = $req->parameters->{ends} || $req->query('ends');

    my $starts = ParseDate($starts_aux);
    my $ends = ParseDate($ends_aux);

    $c->log->debug("ID resource: ".$id_resource." ID Event: ".$id_event." Start: ".$starts." Ends: ".$ends);

    my $booking = $c->model('DB::Booking')->find( { id => $id } );

    $booking->id_resource($id_resource);
    $booking->id_event($id_event);
    $booking->starts($starts);
    $booking->ends($ends);

    my @old_bookings
        = $c->model('DB::Booking')->search( { id_resource => $id_resource } )
        ;    #Recuperem les reserves que utilitzen el recurs

    my $current_set = DateTime::Span->from_datetimes(
        start => $starts,
        end   => $ends->clone->subtract( seconds => 1 )
    );

    my $old_booking_set;
    my $overlap_aux;
    my $overlap = 0;

    foreach (@old_bookings) {
        if ( $_->id ne $id ) { $overlap = $_->overlap($current_set); }
        if ($overlap) {
            last;
        }
    }

    if ($overlap) {
        $c->stash->{template} = 'fail.tt';
        $c->response->status(404);
        $c->forward( $c->view('TT') );
    }
    else {
        $booking->update;

        my @booking = $booking->hash_booking;

        $c->stash->{content} = \@booking;
        $c->response->status(200);
        $c->forward( $c->view('JSON') );
    }

}

sub default_DELETE {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;

    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El DELETE funciona");

    my $booking_aux = $c->model('DB::Booking')->find( { id => $id } );

    if ($booking_aux) {
        $booking_aux->delete;
        $c->stash->{template} = 'booking/delete_ok.tt';
        $c->response->status(200);
        $c->forward( $c->view('TT') );
    }
    else {
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
        $c->forward( $c->view('TT') );
    }
}

sub ParseDate {
  my ($date_str) = @_;

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
