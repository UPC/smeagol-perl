package V2::Server::Controller::Exception;

use Moose;
use feature 'switch';
use namespace::autoclean;
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Span;

# Voodoo modules
use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Exception - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 begin

Begin is the first function executed when a request directed to /booking is made.
Some parameters must be saved in the stash, otherwise they are lost once the object
Catalyst::REST::Request is created (which overwrites the original $c->request).

=cut

sub begin : Private {
    my ( $self, $c ) = @_;
    $c->stash->{id_booking} = $c->request->query_parameters->{booking};
    $c->stash->{id_event}   = $c->request->query_parameters->{event};
    $c->stash->{ical}       = $c->request->query_parameters->{ical};
    $c->stash->{format}     = $c->request->headers->{"accept"} || 'application/json';
}

=head2 default

/booking is mapped to this function.
It redirects to default_GET, default_POST, etc depending on the http method used.

=cut

sub default : Local : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub default_GET {
    my ( $self, $c, $res, $id ) = @_;

    if ($id) {
        $c->detach( 'get_exception', [$id] );
    }
    else {
        if ( $c->stash->{id_booking} ) {
            $c->detach( 'exception_booking', [] );
        }
        else {
            if ( $c->stash->{id_event} ) {
                $c->detach( 'exception_event', [] );
            }
            else {
                $c->detach( 'exception_list', [] );
            }
        }
    }
}

sub exception_list : Local {
    my ( $self, $c ) = @_;

    my @found_exceptions    = $c->model('DB::TException')->all;
    my @exception_list      = map { $_->as_hash } @found_exceptions;
    $c->stash->{content}    = \@exception_list;
    $c->stash->{exceptions} = \@exception_list;

    my @found_bookings      = $c->model('DB::TBooking')->all;
    $c->stash->{bookings}   = \@found_bookings;
    $c->stash->{template}   = 'exception/get_list.tt';

    $c->response->status(200);
}

sub get_exception : Local {
    my ( $self, $c, $id ) = @_;

    my $found_exception = $c->model('DB::TException')->find( { id => $id } );
    if ( ! $found_exception ) {
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    my $exception          = $found_exception->as_hash;
    $c->stash->{content}   = $exception;
    $c->stash->{exception} = $exception;
    $c->stash->{template}  = 'exception/get_exception.tt';
    $c->response->status(200);
}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;

    my $id_booking = $req->parameters->{id_booking};

    my $dtstart = $req->parameters->{dtstart};
    my $dtend   = $req->parameters->{dtend};
    my $duration;

    # dtstart and dtend are parsed in case that some needed parameters
    # to build the recurrence of the booking aren't provided
    $dtstart  = ParseDate($dtstart);
    $dtend    = ParseDate($dtend);
    $duration = $dtend - $dtstart;

    my $freq         = $req->parameters->{freq}      || 'yearly';
    my $interval     = $req->parameters->{interval}  || 1;
    my $until        = $req->parameters->{until}     || $req->parameters->{dtend};
    my $by_minute    = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour      = $req->parameters->{by_hour}   || $dtstart->hour;
    my $by_day       = $req->parameters->{by_day};
    my $by_month     = $req->parameters->{by_month};       # $dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month};

    my $new_exception = $c->model('DB::TException')->find_or_new();

    # Duration is saved in minuntes in the DB in order to make it easier
    # to deal with it when the server builds the JSON objects.
    # Don't mess with the duration, the result can be weird.
    $new_exception->id_booking($id_booking);
    $new_exception->dtstart($dtstart);
    $new_exception->dtend($dtend);
    $new_exception->duration( $duration->in_units("minutes") );
    $new_exception->frequency($freq);
    $new_exception->interval($interval);
    $new_exception->until($until);
    $new_exception->by_minute($by_minute);
    $new_exception->by_hour($by_hour);

    if ( $freq eq 'weekly' || $freq eq 'yearly' ) {
        $new_exception->by_day($by_day);
    }

    if ( $freq eq 'monthly' || $freq eq 'yearly' ) {
        $new_exception->by_month($by_month);
        $new_exception->by_day_month($by_day_month);
    }

    my $exception = $new_exception->as_hash;

    $c->stash->{new_exception} = $new_exception;

    $c->visit( '/check/check_exception', [] );
    my $boo = $c->model('DB::TBooking')
        ->find( { id => $new_exception->id_booking->id } );

    if ($boo) {
        $c->stash->{boo_ok} = 1;
    }
    else {
        $c->stash->{boo_ok} = 0;
    }

    if ( $c->stash->{boo_ok} == 1 ) {

        if ( $c->stash->{empty} == 1 ) {
            $c->stash->{content}  = [ { message => "Bad Request" } ];
            $c->stash->{error}    = "Error: Bad parameters";
            $c->stash->{template} = 'exception/get_list.tt';
            $c->response->status(400);
        }
        else {
            $new_exception->insert;
            $exception->{id}       = $new_exception->id;
            $c->stash->{content}   = $exception;
            $c->stash->{exception} = $exception;
            $c->stash->{template}  = 'exception/get_exception.tt';
            $c->response->status(201);
        }
    }
    else {
        $c->stash->{content}  = [ { message => "Error: Check if the booking exist" } ];
        $c->stash->{error}    = "Error: Check if the booking exist";
        $c->stash->{template} = 'exception/get_list.tt';
        $c->response->status(400);
    }
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;

    my $id_booking = $req->parameters->{id_booking};
    my $dtstart    = $req->parameters->{dtstart};
    my $dtend      = $req->parameters->{dtend};

    # dtstart and dtend are parsed in case that some needed parameters
    # to build the recurrence of the booking aren't provided
    $dtstart     = ParseDate($dtstart);
    $dtend       = ParseDate($dtend);
    my $duration = $dtend - $dtstart;

    my $freq         = $req->parameters->{freq}      || 'yearly';
    my $interval     = $req->parameters->{interval}  || 1;
    my $until        = $req->parameters->{until}     || $req->parameters->{dtend};
    my $by_minute    = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour      = $req->parameters->{by_hour}   || $dtstart->hour;
    my $by_day       = $req->parameters->{by_day};
    my $by_month     = $req->parameters->{by_month};       # $dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month};

    my $found_exception = $c->model('DB::TException')->find( { id => $id } );

    # Duration is saved in minuntes in the DB in order to make it easier
    # to deal with it when the server builds the JSON objects.
    # Don't mess with the duration, the result can be weird.
    $found_exception->id_booking($id_booking);
    $found_exception->dtstart($dtstart);
    $found_exception->dtend($dtend);
    $found_exception->duration( $duration->in_units("minutes") );
    $found_exception->frequency($freq);
    $found_exception->interval($interval);
    $found_exception->until($until);
    $found_exception->by_minute($by_minute);
    $found_exception->by_hour($by_hour);

    if ( $freq eq 'weekly' || $freq eq 'yearly' ) {
        $found_exception->by_day($by_day);
    }

    if ( $freq eq 'monthly' || $freq eq 'yearly' ) {
        $found_exception->by_month($by_month);
        $found_exception->by_day_month($by_day_month);
    }

    my $exception = $found_exception->as_hash;

    $c->stash->{new_exception} = $found_exception;

    $c->visit( '/check/check_exception', [] );
    if ( $c->model('DB::TBooking')
        ->find( { id => $found_exception->id_booking } ) )
    {

        if ( $c->stash->{empty} == 1 ) {
            $c->stash->{content}  = [ { message => "Bad Request" } ];
            $c->stash->{error}    = "Error: Bad parameters";
            $c->stash->{template} = 'exception/get_list.tt';
            $c->response->status(400);
        }
        else {
            $found_exception->update;

            $c->stash->{content} = $exception;
            $c->stash->{booking} = $exception;
            $c->response->status(201);
            $c->forward( 'get_exception', [ $found_exception->id ] );
        }
    }
    else {
        $c->stash->{content}  = [ { message => "Error: Check if the booking exist" } ];
        $c->stash->{error}    = "Error: Check if the booking exist";
        $c->stash->{template} = 'exception/get_list.tt';
        $c->response->status(400);
    }
}

sub default_DELETE {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;

    my $found_exception = $c->model('DB::TException')->find( { id => $id } );

    if ($found_exception) {
        $found_exception->delete;
        $c->stash->{content}  = [ { message => "Exception succesfully deleted" } ];
        $c->stash->{template} = 'exception/delete_ok.tt';
        $c->response->status(200);
    }
    else {
        $c->stash->{content}  = [ { message => "We have not found the exception. Maybe it's already deleted" } ];
        $c->stash->{template} = 'not_found.tt';
        $c->response->status(404);
    }
}

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->stash->{ical} ) {

    }
    else {
        if ( $c->stash->{format} ne "application/json" ) {
            $c->res->content_type("text/html");
            $c->forward( $c->view('HTML') );
        }
        else {
            $c->forward( $c->view('JSON') );
        }
    }
}

sub ParseDate {
    my ($date_str) = @_;

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

=head1 AUTHOR

jamoros,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
