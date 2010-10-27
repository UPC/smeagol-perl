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
	$c->log->debug("Duration booking #".$_->id.": ".$_->duration);
        push( @bookings, @booking );
    }

    $c->stash->{content}  = \@bookings;
    $c->stash->{bookings} = \@bookings;
    my @events = $c->model('DB::Event')->all;
    $c->stash->{events} = \@events;
    my @resources = $c->model('DB::Resources')->all;
    $c->stash->{resources} = \@resources;
    $c->stash->{content}   = \@bookings;
    $c->stash->{bookings}  = \@bookings;
    $c->response->status(200);
    $c->stash->{template} = 'booking/get_list.tt';

}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $id_resource = $req->parameters->{id_resource};
    my $id_event    = $req->parameters->{id_event};
    
    my $dtstart     = $req->parameters->{dtstart};
    my $dtend       = $req->parameters->{dtend};
    my $duration;

    my $frequency   = $req->parameters->{frequency};
    my $interval    = $req->parameters->{interval};
    my $until       = $req->parameters->{until};

    my $by_minute = $req->parameters->{by_minute};
    my $by_hour = $req->parameters->{by_hour};
    my $by_day = $req->parameters->{by_day};
    my $by_month = $req->parameters->{by_month};
    my $by_day_month = $req->parameters->{by_day_month};

    my $new_booking = $c->model('DB::Booking')->find_or_new();
    $c->stash->{id_event} = $id_event;
    $c->stash->{id_resource} = $id_resource;

    $c->visit( '/check/check_booking', [ ] )
        ;    #Do the resource and the event exist?

    $dtstart = ParseDate($dtstart);
    $dtend = ParseDate($dtend);
    $duration = $dtend - $dtstart;

    $new_booking->id_resource($id_resource);
    $new_booking->id_event($id_event);
    $new_booking->dtstart($dtstart);
    $new_booking->dtend($dtend);
    $new_booking->duration($duration->in_units("minutes"));
    $new_booking->frequency($frequency);
    $new_booking->interval($interval);
    $new_booking->until($until);
    $new_booking->by_minute($by_minute);
    $new_booking->by_hour($by_hour);
    $new_booking->by_day($by_day);
    $new_booking->by_month($by_month);
    $new_booking->by_day_month($by_day_month);

    $c->visit('/check/check_overlap',[$new_booking]);

    if ( $c->stash->{booking_ok} == 1 ) {

        if ( $c->stash->{overlap} == 1 ) {
            $c->log->debug("Hi ha solapament \n");

            my @message
                = { message => "Error: Overlap with another booking", };
            $c->stash->{content} = \@message;
            $c->response->status(409);
            $c->stash->{error}    = "Error: Overlap with another booking";
            $c->stash->{template} = 'booking/get_list';
        }
        else {
            $new_booking->insert;

            my @booking = $new_booking->hash_booking;

            $c->stash->{content} = \@booking;
            $c->stash->{booking} = \@booking;
            $c->response->status(201);
            $c->stash->{template} = 'booking/get_booking.tt';

        }
    }
    else {
        my @message
            = { message => "Error: Check if the event or the resource exist",
            };
        $c->stash->{content} = \@message;
        $c->response->status(400);
        $c->stash->{error}
            = "Error: Check if the event or the resource exist";
        $c->stash->{template} = 'booking/get_list.tt';

    }
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

    #$c->log->debug(Dumper($req->headers));

    my $id_resource = $req->parameters->{id_resource}
        || $req->query('id_resource');
    my $id_event   = $req->parameters->{id_event} || $req->query('id_event');
    my $starts_aux = $req->parameters->{starts}   || $req->query('starts');
    my $ends_aux   = $req->parameters->{ends}     || $req->query('ends');

    my $starts = ParseDate($starts_aux);
    my $ends   = ParseDate($ends_aux);

    $c->log->debug( "ID resource: "
            . $id_resource
            . " ID Event: "
            . $id_event
            . " Start: "
            . $starts
            . " Ends: "
            . $ends );

    my $booking = $c->model('DB::Booking')->find( { id => $id } );

    $c->visit( '/check/check_booking', [ $id_resource, $id_event ] )
        ;    #Do the resource and the event exist?

    if ( $c->stash->{booking_ok} == 1 ) {

        $booking->id_resource($id_resource);
        $booking->id_event($id_event);
        $booking->starts($starts);
        $booking->ends($ends);

        my @old_bookings = $c->model('DB::Booking')
            ->search( { id_resource => $id_resource } )
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
            $c->response->status(409);
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
    else {
        my @message
            = { message => "Error: Check if the event or the resource exist",
            };
        $c->stash->{content} = \@message;
        $c->response->status(400);
        $c->stash->{error}
            = "Error: Check if the event or the resource exist";
        $c->stash->{template} = 'booking/get_list';
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

    my ( $day, $hour ) = split( /T/, $date_str );

    my ( $year,  $month, $nday ) = split( /-/, $day );
    my ( $nhour, $min)  = split( /:/, $hour );

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
