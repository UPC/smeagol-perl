package V2::Server::Controller::Exception;

use Moose;
use feature 'switch';
use namespace::autoclean;
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::Span;

#Voodoo modules
use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Exception - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

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
    $c->log->debug( Dumper( $c->request->query_parameters ) );
    $c->stash->{format} = $c->request->headers->{"accept"}
        || 'application/json';
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

    my @exception_aux = $c->model('DB::TException')->all;
    my @exception;
    my @exceptions;

    foreach (@exception_aux) {
        @exception = $_->hash_exception;
        $c->log->debug( "Duration booking #" . $_->id . ": " . $_->duration );
        $c->log->debug( "hash_booking: " . Dumper(@exception) );
        push( @exceptions, @exception );
    }

    $c->stash->{content}    = \@exceptions;
    $c->stash->{exceptions} = \@exceptions;
    my @bookings = $c->model('DB::TBooking')->all;
    $c->stash->{bookings} = \@bookings;
    $c->response->status(200);
    $c->stash->{template} = 'exception/get_list.tt';
}

sub get_exception : Local {
    my ( $self, $c, $id ) = @_;

    my $exception_aux = $c->model('DB::TException')->find( { id => $id } );

    my $exception;
    if ($exception_aux) {
        given ( $exception_aux->frequency ) {
            when ('daily') {
                $exception = {
                    id             => $exception_aux->id,
                        id_booking => $exception_aux->id_booking->id,
                        dtstart    => $exception_aux->dtstart->iso8601(),
                        dtend      => $exception_aux->dtend->iso8601(),
                        duration   => $exception_aux->duration,
                        until      => $exception_aux->until->iso8601(),
                        frequency  => $exception_aux->frequency,
                        interval   => $exception_aux->interval,
                        byminute   => $exception_aux->by_minute,
                        byhour     => $exception_aux->by_hour,
                };

            }

            when ('weekly') {
                $exception = {
                    id             => $exception_aux->id,
                        id_booking => $exception_aux->id_booking->id,
                        dtstart    => $exception_aux->dtstart->iso8601(),
                        dtend      => $exception_aux->dtend->iso8601(),
                        duration   => $exception_aux->duration,
                        until      => $exception_aux->until->iso8601(),
                        frequency  => $exception_aux->frequency,
                        interval   => $exception_aux->interval,
                        byminute   => $exception_aux->by_minute,
                        byhour     => $exception_aux->by_hour,
                        byday      => $exception_aux->by_day,
                };

            }

            when ('monthly') {
                $exception = {
                    id             => $exception_aux->id,
                        id_booking => $exception_aux->id_booking->id,
                        dtstart    => $exception_aux->dtstart->iso8601(),
                        dtend      => $exception_aux->dtend->iso8601(),
                        duration   => $exception_aux->duration,
                        until      => $exception_aux->until->iso8601(),
                        frequency  => $exception_aux->frequency,
                        interval   => $exception_aux->interval,
                        byminute   => $exception_aux->by_minute,
                        byhour     => $exception_aux->by_hour,
                        bymonth    => $exception_aux->by_month,
                        bymonthday => $exception_aux->by_day_month
                };
            }

            default {
                $exception = {
                    id             => $exception_aux->id,
                        id_booking => $exception_aux->id_booking->id,
                        dtstart    => $exception_aux->dtstart->iso8601(),
                        dtend      => $exception_aux->dtend->iso8601(),
                        duration   => $exception_aux->duration,
                        until      => $exception_aux->until->iso8601(),
                        frequency  => $exception_aux->frequency,
                        interval   => $exception_aux->interval,
                        byminute   => $exception_aux->by_minute,
                        byhour     => $exception_aux->by_hour,
                        bymonth    => $exception_aux->by_month,
                        bymonthday => $exception_aux->by_day_month
                };
            }
        };

        $c->stash->{content}   = $exception;
        $c->stash->{exception} = $exception;
        $c->response->status(200);
        $c->stash->{template} = 'exception/get_exception.tt';

    }
    else {
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
}

sub default_POST {
    my ( $self, $c ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El POST funciona");

    my $id_booking = $req->parameters->{id_booking};

    my $dtstart = $req->parameters->{dtstart};
    my $dtend   = $req->parameters->{dtend};
    my $duration;

#dtstart and dtend are parsed in case that some needed parameters to build the recurrence of the
#booking aren't provided
    $c->log->debug("Ara parsejarem dtsart");
    $dtstart = ParseDate($dtstart);
    $c->log->debug("Ara parsejarem dtend");
    $dtend    = ParseDate($dtend);
    $duration = $dtend - $dtstart;

    my $freq     = $req->parameters->{freq};
    my $interval = $req->parameters->{interval} || 1;
    my $until    = $req->parameters->{until} || $req->parameters->{dtend};

    my $by_minute = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour   = $req->parameters->{by_hour}   || $dtstart->hour;

    my $by_day = $req->parameters->{by_day};

    my $by_month     = $req->parameters->{by_month};       #$dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month};

    my $new_exception = $c->model('DB::TException')->find_or_new();

    my $exception;

    given ($freq) {

#Duration is saved in minuntes in the DB in order to make it easier to deal with it when the server
#builds the JSON objects
#Don't mess with the duration, the result can be weird.
        when ('daily') {
            $new_exception->id_booking($id_booking);
            $new_exception->dtstart($dtstart);
            $new_exception->dtend($dtend);
            $new_exception->duration( $duration->in_units("minutes") );
            $new_exception->frequency($freq);
            $new_exception->interval($interval);
            $new_exception->until($until);
            $new_exception->by_minute($by_minute);
            $new_exception->by_hour($by_hour);

            my $exception = {
                id         => $new_exception->id,
                id_booking => $new_exception->id_booking,
                dtstart    => $new_exception->dtstart->iso8601(),
                dtend      => $new_exception->dtend->iso8601(),
                until      => $new_exception->until->iso8601(),
                frequency  => $new_exception->frequency,
                interval   => $new_exception->interval,
                duration   => $new_exception->duration,
                by_minute  => $new_exception->by_minute,
                by_hour    => $new_exception->by_hour,
            };
        }

        when ('weekly') {
            $new_exception->id_booking($id_booking);
            $new_exception->dtend($dtend);
            $new_exception->dtstart($dtstart);
            $new_exception->duration( $duration->in_units("minutes") );
            $new_exception->frequency($freq);
            $new_exception->interval($interval);
            $new_exception->until($until);
            $new_exception->by_minute($by_minute);
            $new_exception->by_hour($by_hour);
            $new_exception->by_day($by_day);

            my $exception = {
                id         => $new_exception->id,
                id_booking => $new_exception->id_booking,
                dtstart    => $new_exception->dtstart->iso8601(),
                dtend      => $new_exception->dtend->iso8601(),
                until      => $new_exception->until->iso8601(),
                frequency  => $new_exception->frequency,
                interval   => $new_exception->interval,
                duration   => $new_exception->duration,
                by_minute  => $new_exception->by_minute,
                by_hour    => $new_exception->by_hour,
                by_day     => $new_exception->by_day,
            };

        }

        when ('monthly') {
            $new_exception->id_booking($id_booking);
            $new_exception->dtstart($dtstart);
            $new_exception->dtend($dtend);
            $new_exception->duration( $duration->in_units("minutes") );
            $new_exception->frequency($freq);
            $new_exception->interval($interval);
            $new_exception->until($until);
            $new_exception->by_minute($by_minute);
            $new_exception->by_hour($by_hour);
            $new_exception->by_month($by_month);
            $new_exception->by_day_month($by_day_month);

            my $exception = {
                id           => $new_exception->id,
                id_booking   => $new_exception->id_booking,
                dtstart      => $new_exception->dtstart->iso8601(),
                dtend        => $new_exception->dtend->iso8601(),
                until        => $new_exception->until->iso8601(),
                frequency    => $new_exception->frequency,
                interval     => $new_exception->interval,
                duration     => $new_exception->duration,
                by_minute    => $new_exception->by_minute,
                by_hour      => $new_exception->by_hour,
                by_month     => $new_exception->by_month,
                by_day_month => $new_exception->by_day_month
            };
        }

        default {
            $new_exception->id_booking($id_booking);
            $new_exception->dtstart($dtstart);
            $new_exception->dtend($dtend);
            $new_exception->duration( $duration->in_units("minutes") );
            $new_exception->frequency($freq);
            $new_exception->interval($interval);
            $new_exception->until($until);
            $new_exception->by_minute($by_minute);
            $new_exception->by_hour($by_hour);
            $new_exception->by_day($by_day);
            $new_exception->by_month($by_month);
            $new_exception->by_day_month($by_day_month);

            my $exception = {
                id           => $new_exception->id,
                id_booking   => $new_exception->id_booking,
                dtstart      => $new_exception->dtstart->iso8601(),
                dtend        => $new_exception->dtend->iso8601(),
                until        => $new_exception->until->iso8601(),
                frequency    => $new_exception->frequency,
                interval     => $new_exception->interval,
                duration     => $new_exception->duration,
                by_minute    => $new_exception->by_minute,
                by_hour      => $new_exception->by_hour,
                by_day       => $new_exception->by_day,
                by_month     => $new_exception->by_month,
                by_day_month => $new_exception->by_day_month
            };

        }
    };

    $c->stash->{new_exception} = $new_exception;

    $c->visit( '/check/check_exception', [] );
    my @message;

    my $boo = $c->model('DB::TBooking')
        ->find( { id => $new_exception->id_booking } );
    my $boo_ok;

    if ($boo) {
        $c->stash->{boo_ok} = 1;
    }
    else {
        $c->stash->{boo_ok} = 0;
    }

    if ( $c->stash->{boo_ok} == 1 ) {

        if ( $c->stash->{empty} == 1 ) {
            @message = { message => "Bad Request", };
            $c->response->status(400);
            $c->stash->{content}  = \@message;
            $c->stash->{error}    = "Error: Bad parameters";
            $c->stash->{template} = 'exception/get_list.tt';
        }
        else {
            $new_exception->insert;

            $c->stash->{content} = $exception;
            $c->stash->{booking} = $exception;
            $c->response->status(201);
            $c->forward( 'get_exception', [ $new_exception->id ] );

        }
    }
    else {
        my @message = { message => "Error: Check if the booking exist", };
        $c->stash->{content} = \@message;
        $c->response->status(400);
        $c->stash->{error}    = "Error: Check if the booking exist";
        $c->stash->{template} = 'exception/get_list.tt';

    }
}

sub default_PUT {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;
    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El PUT funciona");

    my $id_booking = $req->parameters->{id_booking};

    my $dtstart = $req->parameters->{dtstart};
    my $dtend   = $req->parameters->{dtend};
    my $duration;

#dtstart and dtend are parsed in case that some needed parameters to build the recurrence of the
#booking aren't provided
    $c->log->debug("Ara parsejarem dtsart");
    $dtstart = ParseDate($dtstart);
    $c->log->debug("Ara parsejarem dtend");
    $dtend    = ParseDate($dtend);
    $duration = $dtend - $dtstart;

    my $freq     = $req->parameters->{freq};
    my $interval = $req->parameters->{interval} || 1;
    my $until    = $req->parameters->{until} || $req->parameters->{dtend};

    my $by_minute = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour   = $req->parameters->{by_hour}   || $dtstart->hour;

    my $by_day = $req->parameters->{by_day};

    my $by_month     = $req->parameters->{by_month};       #$dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month};

    my $exception_aux = $c->model('DB::TException')->find( { id => $id } );

    my $exception;

    given ($freq) {

#Duration is saved in minuntes in the DB in order to make it easier to deal with it when the server
#builds the JSON objects
#Don't mess with the duration, the result can be weird.
        when ('daily') {
            $exception_aux->id_booking($id_booking);
            $exception_aux->dtstart($dtstart);
            $exception_aux->dtend($dtend);
            $exception_aux->duration( $duration->in_units("minutes") );
            $exception_aux->frequency($freq);
            $exception_aux->interval($interval);
            $exception_aux->until($until);
            $exception_aux->by_minute($by_minute);
            $exception_aux->by_hour($by_hour);

            my $exception = {
                id         => $exception_aux->id,
                id_booking => $exception_aux->id_booking,
                dtstart    => $exception_aux->dtstart->iso8601(),
                dtend      => $exception_aux->dtend->iso8601(),
                until      => $exception_aux->until->iso8601(),
                frequency  => $exception_aux->frequency,
                interval   => $exception_aux->interval,
                duration   => $exception_aux->duration,
                by_minute  => $exception_aux->by_minute,
                by_hour    => $exception_aux->by_hour,
            };
        }

        when ('weekly') {
            $exception_aux->id_booking($id_booking);
            $exception_aux->dtend($dtend);
            $exception_aux->dtstart($dtstart);
            $exception_aux->duration( $duration->in_units("minutes") );
            $exception_aux->frequency($freq);
            $exception_aux->interval($interval);
            $exception_aux->until($until);
            $exception_aux->by_minute($by_minute);
            $exception_aux->by_hour($by_hour);
            $exception_aux->by_day($by_day);

            my $exception = {
                id         => $exception_aux->id,
                id_booking => $exception_aux->id_booking,
                dtstart    => $exception_aux->dtstart->iso8601(),
                dtend      => $exception_aux->dtend->iso8601(),
                until      => $exception_aux->until->iso8601(),
                frequency  => $exception_aux->frequency,
                interval   => $exception_aux->interval,
                duration   => $exception_aux->duration,
                by_minute  => $exception_aux->by_minute,
                by_hour    => $exception_aux->by_hour,
                by_day     => $exception_aux->by_day,
            };

        }

        when ('monthly') {
            $exception_aux->id_booking($id_booking);
            $exception_aux->dtstart($dtstart);
            $exception_aux->dtend($dtend);
            $exception_aux->duration( $duration->in_units("minutes") );
            $exception_aux->frequency($freq);
            $exception_aux->interval($interval);
            $exception_aux->until($until);
            $exception_aux->by_minute($by_minute);
            $exception_aux->by_hour($by_hour);
            $exception_aux->by_month($by_month);
            $exception_aux->by_day_month($by_day_month);

            my $exception = {
                id           => $exception_aux->id,
                id_booking   => $exception_aux->id_booking,
                dtstart      => $exception_aux->dtstart->iso8601(),
                dtend        => $exception_aux->dtend->iso8601(),
                until        => $exception_aux->until->iso8601(),
                frequency    => $exception_aux->frequency,
                interval     => $exception_aux->interval,
                duration     => $exception_aux->duration,
                by_minute    => $exception_aux->by_minute,
                by_hour      => $exception_aux->by_hour,
                by_month     => $exception_aux->by_month,
                by_day_month => $exception_aux->by_day_month
            };
        }

        default {
            $exception_aux->id_booking($id_booking);
            $exception_aux->dtstart($dtstart);
            $exception_aux->dtend($dtend);
            $exception_aux->duration( $duration->in_units("minutes") );
            $exception_aux->frequency($freq);
            $exception_aux->interval($interval);
            $exception_aux->until($until);
            $exception_aux->by_minute($by_minute);
            $exception_aux->by_hour($by_hour);
            $exception_aux->by_day($by_day);
            $exception_aux->by_month($by_month);
            $exception_aux->by_day_month($by_day_month);

            my $exception = {
                id           => $exception_aux->id,
                id_booking   => $exception_aux->id_booking,
                dtstart      => $exception_aux->dtstart->iso8601(),
                dtend        => $exception_aux->dtend->iso8601(),
                until        => $exception_aux->until->iso8601(),
                frequency    => $exception_aux->frequency,
                interval     => $exception_aux->interval,
                duration     => $exception_aux->duration,
                by_minute    => $exception_aux->by_minute,
                by_hour      => $exception_aux->by_hour,
                by_day       => $exception_aux->by_day,
                by_month     => $exception_aux->by_month,
                by_day_month => $exception_aux->by_day_month
            };

        }
    };

    $c->stash->{new_exception} = $exception_aux;

    $c->visit( '/check/check_exception', [] );
    my @message;
    if ( $c->model('DB::TBooking')
        ->find( { id => $exception_aux->id_booking } ) )
    {

        if ( $c->stash->{empty} == 1 ) {
            @message = { message => "Bad Request", };
            $c->response->status(400);
            $c->stash->{content}  = \@message;
            $c->stash->{error}    = "Error: Bad parameters";
            $c->stash->{template} = 'exception/get_list.tt';
        }
        else {
            $exception_aux->update;

            $c->stash->{content} = $exception;
            $c->stash->{booking} = $exception;
            $c->response->status(201);
            $c->forward( 'get_exception', [ $exception_aux->id ] );

        }
    }
    else {
        my @message = { message => "Error: Check if the booking exist", };
        $c->stash->{content} = \@message;
        $c->response->status(400);
        $c->stash->{error}    = "Error: Check if the booking exist";
        $c->stash->{template} = 'exception/get_list.tt';

    }
}

sub default_DELETE {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;

    $c->log->debug( 'Mètode: ' . $req->method );
    $c->log->debug("El DELETE funciona");

    my $exception_aux = $c->model('DB::TException')->find( { id => $id } );

    if ($exception_aux) {
        $exception_aux->delete;
        my @message = { message => "Exception succesfully deleted" };
        $c->stash->{content}  = \@message;
        $c->stash->{template} = 'exception/delete_ok.tt';
        $c->response->status(200);
    }
    else {
        my @message
            = { message =>
                "We have not found the exception. Maybe it's already deleted"
            };
        $c->stash->{content}  = \@message;
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
