package V2::Server::Controller::Booking;

use Moose;
use feature 'switch';
use namespace::autoclean;
use DateTime;
use DateTime::Duration;
use DateTime::Span;

# Voodoo modules
use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

use JSON::Any;

my $VERSION = $V2::Server::VERSION;
BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Booking - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 begin

Begin is the first function executed when a request directed to
/booking is made. Some parameters must be saved in the stash,
otherwise they are lost once the object Catalyst::REST::Request
is created (which overwrites the original $c->request).

=cut

sub begin : Private {
    my ( $self, $c ) = @_;

    $c->stash->{id_resource} = $c->request->query_parameters->{resource};
    $c->stash->{id_event}    = $c->request->query_parameters->{event};
    $c->stash->{ical}        = $c->request->query_parameters->{ical};
    $c->stash->{format}      = $c->request->headers->{"accept"} || 'application/json';
}

=head2 default

/booking is mapped to this function. It redirects to default_GET,
default_POST, etc depending on the http method used.

=cut

sub default : Local : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

=head2 default_GET

There are 3 options:

=over 4

=item *

Complete list of bookings (not very useful): /booking GET which
redirects to the Private function get_list

=item *

A booking: /booking/id GET which redirects to the Private
function get_booking

=item *

A resource's agenda: /booking?resource=id GET which redirects to
bookings_resource

=back

=cut

sub default_GET {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;

    if ($id) {
        if ( ( defined $module ) && ( $module eq 'tag' ) ) {
            if ($id_module) {
                $c->detach( 'get_relation_tag_booking', [ $id, $id_module ] );
            }
            else {
                $c->response->location( $c->uri_for('/tag') . "/?booking=" . $id );

                # TODO: message: redireccio a la llista
                $c->stash->{content} = [];
                $c->response->status(301);
            }
        }
        else {
            $c->detach( 'get_booking', [$id] );
        }
    }
    else {
        if ( $c->stash->{id_resource} ) {
            $c->detach( 'bookings_resource', [] );
        }
        else {
            if ( $c->stash->{id_event} ) {
                $c->detach( 'bookings_event', [] );
            }
            else {
                $c->detach( 'booking_list', [] );
            }
        }
    }
}

sub get_relation_tag_booking : Private {
    my ( $self, $c, $id, $id_module ) = @_;

    my $found_booking = $c->model('DB::TBooking')->find( { id => $id } );
    if ( ! $found_booking ) {
        # TODO: message: Resource no trobat.
        $c->stash->{content}  = [];
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    $c->detach( '/tag/get_tag_from_object', [ $id, $c->namespace, $id_module ] );
}

=head2 get_booking

This function is not accessible through the url:
/booking/get_booking/id but /booking/id hence the Private type.

See default_GET for details.

=cut

sub get_booking : Private {
    my ( $self, $c, $id ) = @_;

    my $found_booking = $c->model('DB::TBooking')->find( { id => $id } );
    if ( ! $found_booking ) {
        #TODO: Booking no Trobat.
        $c->stash->{content}  = [];
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    my %booking = (
        id           => $found_booking->id,
        info         => $found_booking->info,
        id_resource  => $found_booking->id_resource->id,
        id_event     => $found_booking->id_event->id,
        dtstart      => $found_booking->dtstart->iso8601(),
        dtend        => $found_booking->dtend->iso8601(),
        duration     => $found_booking->duration,
        until        => $found_booking->until->iso8601(),
        frequency    => $found_booking->frequency,
        interval     => $found_booking->interval,
        by_minute    => $found_booking->by_minute,
        by_hour      => $found_booking->by_hour,
        by_day       => $found_booking->by_day,
        by_month     => $found_booking->by_month,
        by_day_month => $found_booking->by_day_month,
    );

    $c->stash->{content}  = \%booking;
    $c->stash->{booking}  = \%booking;
    $c->stash->{template} = 'booking/get_booking.tt';
    $c->response->status(200);
}

=head2 booking_list

Private function accessible through /booking GET 
It returns every booking of every resource. 

=cut

sub booking_list : Private {
    my ( $self, $c ) = @_;

    my @found_bookings     = $c->model('DB::TBooking')->all;
    my @booking_list       = map { $_->as_hash } @found_bookings;
    $c->stash->{content}   = \@booking_list;
    $c->stash->{bookings}  = \@booking_list;

    my @found_events       = $c->model('DB::TEvent')->all;
    $c->stash->{events}    = \@found_events;

    my @found_resources    = $c->model('DB::TResource')->all;
    $c->stash->{resources} = \@found_resources;
    $c->stash->{template}  = 'booking/get_list.tt';

    $c->response->status(200);
}

=head2 bookings_resource

It returns the agenda of a resource.
$id has been got from $c->stash->{id_resource} as you can see in default_GET

=cut

sub bookings_resource : Private {
    my ( $self, $c ) = @_;

    my $id   = $c->stash->{id_resource};
    my $ical = $c->stash->{ical};

    if ($ical) {
        $c->detach( 'ical', [] );
    }

    my @found_bookings = $c->model('DB::TBooking')->search( { id_resource => $id } );

    my @booking_list = map { $_->as_hash } @found_bookings;

    # Whatever is put inside $c->stash->{content} is encoded
    # to JSON, if that's the view requested
    $c->stash->{content} = \@booking_list;

    # The HTML view uses $c->stash->{booking} because it makes
    # clearer and more understandable the TT templates
    $c->stash->{bookings} = \@booking_list;

    # Events and Resources are passed to the HTML view in order
    # to build the select menus
    my @found_events       = $c->model('DB::TEvent')->all;
    $c->stash->{events}    = \@found_events;
    my @found_resources    = $c->model('DB::TResource')->all;
    $c->stash->{resources} = \@found_resources;
    $c->stash->{template}  = 'booking/get_list.tt';

    $c->response->status(200);
}

=head2 bookings_event

=cut

sub bookings_event : Private {
    my ( $self, $c ) = @_;

    my $id   = $c->stash->{id_event};
    my $ical = $c->stash->{ical};

    if ($ical) {
        $c->detach( 'ical_event', [] );
    }

    my @found_bookings = $c->model('DB::TBooking')->search( { id_event => $id } );
    my @booking_list   = map { $_->as_hash } @found_bookings;

    $c->stash->{content}   = \@booking_list;
    $c->stash->{bookings}  = \@booking_list;
    my @found_events       = $c->model('DB::TEvent')->all;
    $c->stash->{events}    = \@found_events;
    my @found_resources    = $c->model('DB::TResource')->all;
    $c->stash->{resources} = \@found_resources;
    $c->stash->{template}  = 'booking/get_list.tt';

    $c->response->status(200);
}

=head2 default_POST

This function creates a booking for a resource and associate it
to an event.

After checking that the event and the resource actually exist,
we proceed to insert the booking in the table booking of the DB
if, and only if, there isn't overlapping with another previously
existing booking.

Some of the check_[....] functions are reused by other modules,
so I've put them together in the controller Check.

check_overlap is an special case, some may suggest that it should
be placed in the Schema/Booking.pm but by doing that the only
thing that we achieve is an increase of code complexity.
$c for the win!

=cut

sub default_POST {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;

    my $req = $c->request;

    if ( ( defined $module ) && ( $module eq 'tag' ) ) {
        $c->detach('post_relation_tag_booking');
    }

    my $info        = $req->parameters->{info};
    my $id_resource = $req->parameters->{id_resource};
    my $id_event    = $req->parameters->{id_event};
    my $dtstart     = $req->parameters->{dtstart};
    my $dtend       = $req->parameters->{dtend};

    my $exception;
    if ( $req->parameters->{exception} ) {
        my $j = JSON::Any->new;
        my $e = $j->jsonToObj( $req->parameters->{exception} );

        my ( $ex_year, $ex_month, $ex_day ) = split( '-', $e->{exception} );
        $exception = DateTime->new(
            year  => $ex_year,
            month => $ex_month,
            day   => $ex_day
        );
    }

    # dtstart and dtend are parsed in case that some needed
    # parameters to build the recurrence of the booking aren't
    # provided.
    $dtstart  = ParseDate($dtstart);
    $dtend    = ParseDate($dtend);
    my $duration = $dtend - $dtstart;

    my $freq         = $req->parameters->{frequency}    || "daily";
    my $interval     = $req->parameters->{interval}     || 1;
    my $until        = $req->parameters->{until}        || $req->parameters->{dtend};
    my $by_minute    = $req->parameters->{by_minute}    || $dtstart->minute;
    my $by_hour      = $req->parameters->{by_hour}      || $dtstart->hour;
    my $by_day       = $req->parameters->{by_day}       || undef;
    my $by_month     = $req->parameters->{by_month}     || undef;    # $dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month} || undef;

    # Do the resource and the event exist?
    $c->stash->{id_event}    = $id_event;
    $c->stash->{id_resource} = $id_resource;
    $c->visit( '/check/check_booking', [] );

    # Creat the Booking...
    my $new_booking = $c->model('DB::TBooking')->find_or_new();
    $new_booking->info($info);
    $new_booking->id_resource($id_resource);
    $new_booking->id_event($id_event);
    $new_booking->dtstart($dtstart);
    $new_booking->dtend($dtend);
    $new_booking->duration( $duration->in_units("minutes") );
    $new_booking->frequency($freq);
    $new_booking->interval($interval);
    $new_booking->until($until);
    $new_booking->by_minute($by_minute);
    $new_booking->by_hour($by_hour);
    $new_booking->by_day($by_day);
    $new_booking->by_month($by_month);
    $new_booking->by_day_month($by_day_month);

    my $booking = {
        id           => $new_booking->id,
        info         => $new_booking->info,
        id_resource  => $new_booking->id_resource->id,
        id_event     => $new_booking->id_event->id,
        dtstart      => $new_booking->dtstart->iso8601(),
        dtend        => $new_booking->dtend->iso8601(),
        until        => $new_booking->until->iso8601(),
        frequency    => $new_booking->frequency,
        interval     => $new_booking->interval,
        duration     => $new_booking->duration,
        by_minute    => $new_booking->by_minute,
        by_hour      => $new_booking->by_hour,
        by_day       => $new_booking->by_day,
        by_month     => $new_booking->by_month,
        by_day_month => $new_booking->by_day_month,
    };

    $c->stash->{new_booking} = $new_booking;
    if ( $c->request->parameters->{exception} ) {
        $c->stash->{new_exception} = $exception;
    }

    $c->forward( '/check/check_overlap', [] );

    if ( ! $c->stash->{booking_ok} ) {
        # TODO: message: parametres estan malament
        $c->stash->{content}  = [];
        $c->stash->{error}    = "Error: Check if the event or the resource exist";
        $c->stash->{template} = 'booking/get_list.tt';
        $c->response->status(400);
        return;
    }

    if (   $c->stash->{overlap}  == 1
        or $c->stash->{empty}    == 1
        or $c->stash->{too_long} == 1 )
    {
        if ( $c->stash->{empty} == 1 ) {
            # TODO: message: parametres estan malament
            $c->response->status(400);
        }
        else {
            # TODO: message: Booking amb resource ocupat
            $c->response->status(409);
        }
        $c->stash->{content}  = [];
        $c->stash->{error}    = "Error: Overlap with another booking or bad parameters";
        $c->stash->{template} = 'booking/get_list.tt';
        return;
    }

    $new_booking->insert;
    # TODO: booking creat correctament
    $c->stash->{content} = [];
    $c->stash->{booking} = $booking;
    # $c->stash->{template} = 'booking/get_booking.tt';

    $c->response->status(201);
    $c->response->location( $req->uri->as_string . "/" . $new_booking->id );
    # $c->forward( 'get_booking', [ $new_booking->id ] );
}

sub post_relation_tag_booking : Private {
    my ( $self, $c ) = @_;

    # TODO: operacio no permesa.
    $c->stash->{content} = [];
    $c->response->status(405);
}

=head2 default_PUT

Same functionality than default_POST but updating an existing booking.

=cut

sub default_PUT {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;

    if ($id) {
        if ( ( defined $module ) && ( $module eq 'tag' ) && ($id_module) ) {
            $c->forward( 'put_relation_tag_booking', [ $id, $id_module ] );
        }
        else {
            $c->forward( 'put_booking', [$id] );
        }
    }
}

sub put_booking : Private {
    my ( $self, $c, $id ) = @_;

    my $req           = $c->request;
    my $found_booking = $c->model('DB::TBooking')->find( { id => $id } );
    if ( ! $found_booking ) {
        $c->stash->{content}  = [];
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    my $info        = $req->parameters->{info};
    my $id_resource = $req->parameters->{id_resource};
    my $id_event    = $req->parameters->{id_event};
    my $dtstart     = $req->parameters->{dtstart};
    my $dtend       = $req->parameters->{dtend};

    # dtstart and dtend are parsed in case that some needed
    # parameters to build the recurrence of thee booking aren't
    # provided.
    $dtstart     = ParseDate($dtstart);
    $dtend       = ParseDate($dtend);
    my $duration = $dtend - $dtstart;

    my $freq      = $req->parameters->{frequency} || "daily";
    my $interval  = $req->parameters->{interval}  || 1;
    my $until     = $req->parameters->{until}     || $req->parameters->{dtend};
    my $by_minute = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour   = $req->parameters->{by_hour}   || $dtstart->hour;

    # by_day may not be provided, so in order to build a proper
    # ICal object, an array containing English day abbreviations
    # is needed.
    my @day_abbr     = ( 'mo', 'tu', 'we', 'th', 'fr', 'sa', 'su' );
    my $by_day       = $req->parameters->{by_day}       || $day_abbr[ $dtstart->day_of_week - 1 ];
    my $by_month     = $req->parameters->{by_month}     || $dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month} || undef;

    # Do the resource and the event exist?
    $c->stash->{id_event}    = $id_event;
    $c->stash->{id_resource} = $id_resource;
    $c->visit( '/check/check_booking', [] );

    # Duration is saved in minuntes in the DB in order to make
    # it easier to deal with it when the server builds the JSON
    # objects. Don't mess with the duration, the result can be weird.

    $found_booking->info($info);
    $found_booking->id_resource($id_resource);
    $found_booking->id_event($id_event);
    $found_booking->dtstart($dtstart);
    $found_booking->dtend($dtend);
    $found_booking->duration( $duration->in_units("minutes") );
    $found_booking->frequency($freq);
    $found_booking->interval($interval);
    $found_booking->until($until);
    $found_booking->by_minute($by_minute);
    $found_booking->by_hour($by_hour);
    $found_booking->by_day($by_day);
    $found_booking->by_month($by_month);
    $found_booking->by_day_month($by_day_month);

    my $booking = {
        id           => $found_booking->id,
        info         => $found_booking->info,
        id_resource  => $found_booking->id_resource->id,
        id_event     => $found_booking->id_event->id,
        dtstart      => $found_booking->dtstart->iso8601(),
        dtend        => $found_booking->dtend->iso8601(),
        until        => $found_booking->until->iso8601(),
        frequency    => $found_booking->frequency,
        interval     => $found_booking->interval,
        duration     => $found_booking->duration,
        by_minute    => $found_booking->by_minute,
        by_hour      => $found_booking->by_hour,
        by_day       => $found_booking->by_day,
        by_month     => $found_booking->by_month,
        by_day_month => $found_booking->by_day_month,
    };

    # We are reusing /check/check_overlap that's why $found_booking
    # is saved in $c->stash->{new_booking}. For the same reason
    # we put to true $c->stash->{PUT} so we'll be able to amply
    # the convenient restrictions to the search query
    # (see check module for details).
    $c->stash->{new_booking} = $found_booking;
    $c->stash->{PUT}         = 1;
    $c->visit( '/check/check_overlap', [] );

    if ( ! $c->stash->{booking_ok} ) {
        $c->stash->{content}  = [];
        $c->stash->{error}    = "Error: Check if the event or the resource exist";
        $c->stash->{template} = 'booking/get_list.tt';
        $c->response->status(404);
        return;
    }

    if (   $c->stash->{overlap}  == 1
        or $c->stash->{empty}    == 1
        or $c->stash->{too_long} == 1 )
    {
        if ( $c->stash->{empty} == 1 ) {
            $c->stash->{content}  = [];
            $c->stash->{error}    = "Error: Bad request. Check parameters";
            $c->stash->{template} = 'booking/get_list.tt';
            $c->response->status(400);
        }
        else {
            # TODO: Recurs o event ocupat
            $c->stash->{content} = [];
            $c->response->status(409);
        }
        return;
    }

    $found_booking->update;
    $c->stash->{content}  = [];
    $c->stash->{booking}  = $booking;
    $c->stash->{template} = 'booking/get_booking.tt';
    $c->response->status(200);
}

sub put_relation_tag_booking : Private {
    my ( $self, $c, $id_booking, $id_module ) = @_;

    my $found_booking = $c->model('DB::TBooking')->find( { id => $id_booking } );
    if ( ! $found_booking ) {
        # TODO: message: Booking no trobat.
        $c->stash->{content}  = [];
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    $c->detach( '/tag/put_tag_object', [ $id_booking, $c->namespace, $id_module ] );
}

=head2 default_DELETE

=cut

sub default_DELETE {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;

    my $req = $c->request;

    if ( $id && defined $module && $module eq 'tag' && $id_module ) {
        $c->detach( 'delete_relation_tag_booking', [ $id, $id_module ] );
        return;
    }

    my $found_booking = $c->model('DB::TBooking')->find( { id => $id } );
    if ( ! $found_booking ) {
        # TODO: message: Resource no trobat.
        $c->stash->{content}  = [];
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    $found_booking->delete;
    # TODO: message: Resource esborrat amb èxit.
    $c->stash->{content} = [];
    $c->response->status(200);
}

sub delete_relation_tag_booking : Private {
    my ( $self, $c, $id, $id_module ) = @_;

    my $found_booking = $c->model('DB::TBooking')->find( { id => $id } );
    if ( ! $found_booking ) {
        # TODO: message: Resource no trobat.
        $c->stash->{content}  = [];
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
        return;
    }

    $c->detach( '/tag/delete_tag_from_object', [ $id, $c->namespace, $id_module ] );
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

=head2 end

The last function executed before responding the request.
Because we saved format in $c->stash->{format} it allow us
to choose between the available views.

=cut

sub end : Private {
    my ( $self, $c ) = @_;

    return if $c->stash->{ical};

    if ( $c->stash->{format} eq "application/json" ) {
        $c->forward( $c->view('JSON') );
    }
    else {
        $c->res->content_type("text/html");
        $c->stash->{VERSION} = $VERSION;
        $c->forward( $c->view('HTML') );
    }
}

=head2 ical

=cut

sub ical : Private {
    my ( $self, $c ) = @_;

    my $filename = "agenda_resource_" . $c->stash->{id_resource} . ".ics";
    my $calendar = Data::ICal->new();

    $calendar->add_property( prodid => "//UPC//Smeagol Server//EN" );
    $calendar->add_property( version => "2.0" );

    my @found_bookings = $c->model('DB::TBooking')->search( { id_resource => $c->stash->{id_resource} } );
    my @booking_list   = map { $_->as_hash } @found_bookings;

    for my $booking (@booking_list) {
        my $event        = Data::ICal::Entry::Event->new();
        my $dtstart      = ParseDate( $booking->{dtstart} );
        my $dtend        = ParseDate( $booking->{dtend} );
        my $until        = ParseDate( $booking->{until} );

        my $dtstart_ical = Date::ICal->new(
            year   => $dtstart->year,
            month  => $dtstart->month,
            day    => $dtstart->day,
            hour   => $dtstart->hour,
            minute => $dtstart->minute,
        );

        my $dtend_ical = Date::ICal->new(
            year   => $dtend->year,
            month  => $dtend->month,
            day    => $dtend->day,
            hour   => $dtend->hour,
            minute => $dtend->minute,
        );

        my $until_ical = Date::ICal->new(
            year   => $until->year,
            month  => $until->month,
            day    => $until->day,
            hour   => $until->hour,
            minute => $until->minute,
        );

        # my @exrule_list = @{ $booking->{exrule_list} };
        # for my $exrule (@exrule_list) {
        #     $event->add_properties( exrule => $exrule->{exrule} );
        # }

        $event->add_properties(
            uid     => $booking->{id},
            summary => "Booking #" . $booking->{id},
            dtstart => $dtstart_ical->ical,
            dtend   => $dtend_ical->ical,
            rrule   => _ical_dispatch( $booking, $until_ical ),
        );

        $calendar->add_entry($event);
    }

    $c->stash->{content} = \@booking_list;
    $c->res->content_type("text/calendar");
    $c->res->header( 'Content-Disposition' => qq(inline; filename=$filename) );

    # Due to the fact that after numbers within exrule parameters
    # apears \ character we must parse the calendar string before
    # sending it. We need to scape \ char.
    my $calendar_ics = $calendar->as_string;
    $calendar_ics =~ s/\\//g;
    $c->res->output($calendar_ics);
}

=head2 ical_event

=cut

sub ical_event : Private {
    my ( $self, $c ) = @_;

    my $filename = "agenda_event_" . $c->stash->{id_event} . ".ics";
    my $calendar = Data::ICal->new();

    $calendar->add_property( prodid => "//UPC//Smeagol Server//EN" );
    $calendar->add_property( version => "2.0" );

    my @found_bookings = $c->model('DB::TBooking')->search( { id_event => $c->stash->{id_event} } );
    my @booking_list   = map { $_->as_hash } @found_bookings;

    for my $booking (@booking_list) {
        my $event            = Data::ICal::Entry::Event->new();
        my $dtstart          = ParseDate( $booking->{dtstart} );
        my $dtend            = ParseDate( $booking->{dtend} );
        my $until            = ParseDate( $booking->{until} );

        my $until_ical = Date::ICal->new(
            year   => $until->year,
            month  => $until->month,
            day    => $until->day,
            hour   => $until->hour,
            minute => $until->minute,
        );

        # my @exrule_list = @{ $booking->{exrule_list} };
        # for my $exrule (@exrule_list) {
        #     $event->add_properties( exrule => $exrule->{exrule} );
        # }

        $event->add_properties(
            uid     => $booking->{id},
            summary => "Booking #" . $booking->{id},
            dtstart => uc($dtstart),
            dtend   => uc($dtend),
            rrule   => _ical_dispatch( $booking, $until_ical ),
        );

        $calendar->add_entry($event);
    }

    $c->res->content_type("text/calendar");
    $c->res->header( 'Content-Disposition' => qq(inline; filename=$filename) );

    # Due to the fact that after numbers within exrule parameters
    # apears \ character we must parse the calendar string before
    # sending it. We need to scape \ char.
    my $calendar_ics = $calendar->as_string;
    $calendar_ics =~ s/\\//g;
    $c->res->output($calendar_ics);
}

sub _ical_dispatch {
    my ( $item, $until ) = @_;

    return 'FREQ=DAILY;INTERVAL='
           . uc( $item->{interval} )
           . ';UNTIL='
           . uc( $until->ical )
        if $item->{frequency} eq 'daily';

    return 'FREQ=WEEKLY;INTERVAL='
           . uc( $item->{interval} )
           . '.;BYDAY='
           . uc( $item->{byday} )
           . ';UNTIL='
           . uc( $until->ical )
        if $item->{frequency} eq 'weekly';

    return 'FREQ=MONTHLY;INTERVAL='
           . uc( $item->{interval} )
           . ';BYMONTHDAY='
           . $item->{bydaymonth}
           . ';UNTIL='
           . uc( $until->ical )
        if $item->{frequency} eq 'monthly';

    return 'FREQ=YEARLY;INTERVAL='
           . uc( $item->{interval} )
           . ';BYMONTH='
           . $item->{bymonth}
           . ';BYMONTHDAY='
           . $item->{bydaymonth}
           . ';UNTIL='
           . uc( $until->ical )
        if $item->{frequency} eq 'yearly';
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
