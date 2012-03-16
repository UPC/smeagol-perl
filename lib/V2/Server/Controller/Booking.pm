package V2::Server::Controller::Booking;

use Moose;
use feature 'switch';
use namespace::autoclean;
use DateTime;
use DateTime::Duration;
use DateTime::Span;
#Voodoo modules
use Date::ICal;
use Data::ICal;
use Data::ICal::Entry::Event;

use JSON::Any;

my $VERSION = $V2::Server::VERSION;
BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::Booking_P - Catalyst Controller

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
    $c->stash->{id_resource} = $c->request->query_parameters->{resource};
    $c->stash->{id_event}    = $c->request->query_parameters->{event};
    $c->stash->{ical}        = $c->request->query_parameters->{ical};
    $c->stash->{format}      = $c->request->headers->{"accept"}
        || 'application/json';
}

=head2 default

/booking is mapped to this function.
It redirects to default_GET, default_POST, etc depending on the http method used.

=cut

sub default : Local : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

=head2 default_GET

There are 3 options:

=over 4

=item *

Complete list of bookings (not very useful): /booking GET which redirects to the Private function
get_list

=item *

A booking: /booking/id GET which redirects to the Private function get_booking

=item *

A resource's agenda: /booking?resource=id GET which redirects to bookings_resource

=back

=cut

sub default_GET {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;
	my @message;


    if ($id) {
		if((defined $module) && ($module eq 'tag') ){
			if ($id_module){
		    	$c->detach( 'get_relation_tag_booking', [$id, $id_module]);
			}else{
				$c->response->location($c->uri_for('/tag')."/?booking=".$id);
				#TODO: message: redireccio a la llista
				$c->stash->{content}  = \@message;
				$c->response->status(301); 
			}
		}else {
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
    my ( $self, $c, $id , $id_module) = @_;
    my $booking = $c->model('DB::TBooking')->find( { id => $id } );
    my @message;

    if ( !$booking ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {

        $c->detach( '/tag/get_tag_from_object', [ $id, $c->namespace, $id_module ] );
    }
}
=head2 get_booking

This function is not accessible through the url: /booking/get_booking/id but /booking/id hence the
Private type.

See default_GET for details.

=cut

sub get_booking : Private {
    my ( $self, $c, $id ) = @_;

    my $booking_aux = $c->model('DB::TBooking')->find( { id => $id } );
    my $booking;
    if ($booking_aux) {
        given ( $booking_aux->frequency ) {
            when ('daily') {
                $booking = {
                    id              => $booking_aux->id,
                        info        => $booking_aux->info,
                        id_resource => $booking_aux->id_resource->id,
                        id_event    => $booking_aux->id_event->id,
                        dtstart     => $booking_aux->dtstart->iso8601(),
                        dtend       => $booking_aux->dtend->iso8601(),
                        duration    => $booking_aux->duration,
                        until       => $booking_aux->until->iso8601(),
                        frequency   => $booking_aux->frequency,
                        interval    => $booking_aux->interval,
                        by_minute    => $booking_aux->by_minute,
                        by_hour      => $booking_aux->by_hour,
                };

            }

            when ('weekly') {
                $booking = {
                    id              => $booking_aux->id,
                        info        => $booking_aux->info,
                        id_resource => $booking_aux->id_resource->id,
                        id_event    => $booking_aux->id_event->id,
                        dtstart     => $booking_aux->dtstart->iso8601(),
                        dtend       => $booking_aux->dtend->iso8601(),
                        duration    => $booking_aux->duration,
                        until       => $booking_aux->until->iso8601(),
                        frequency   => $booking_aux->frequency,
                        interval    => $booking_aux->interval,
                        by_minute    => $booking_aux->by_minute,
                        by_hour      => $booking_aux->by_hour,
                        by_day       => $booking_aux->by_day,
                };

            }

            when ('monthly') {
                $booking = {
                    id              => $booking_aux->id,
                        info        => $booking_aux->info,
                        id_resource => $booking_aux->id_resource->id,
                        id_event    => $booking_aux->id_event->id,
                        dtstart     => $booking_aux->dtstart->iso8601(),
                        dtend       => $booking_aux->dtend->iso8601(),
                        duration    => $booking_aux->duration,
                        until       => $booking_aux->until->iso8601(),
                        frequency   => $booking_aux->frequency,
                        interval    => $booking_aux->interval,
                        by_minute    => $booking_aux->by_minute,
                        by_hour      => $booking_aux->by_hour,
                        by_month     => $booking_aux->by_month,
                        by_monthday  => $booking_aux->by_day_month,
		};
            }

            default {
                $booking = {
                    id              => $booking_aux->id,
                        info        => $booking_aux->info,
                        id_resource => $booking_aux->id_resource->id,
                        id_event    => $booking_aux->id_event->id,
                        dtstart     => $booking_aux->dtstart->iso8601(),
                        dtend       => $booking_aux->dtend->iso8601(),
                        duration    => $booking_aux->duration,
                        until       => $booking_aux->until->iso8601(),
                        frequency   => $booking_aux->frequency,
                        interval    => $booking_aux->interval,
                        by_minute    => $booking_aux->by_minute,
                        by_hour      => $booking_aux->by_hour,
                        by_month     => $booking_aux->by_month,
                        by_monthday  => $booking_aux->by_day_month,
                };
            }
        };

        $c->stash->{content} = $booking;
        $c->stash->{booking} = $booking;
        $c->response->status(200);
        $c->stash->{template} = 'booking/get_booking.tt';

    }
    else {
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
}

=head2 booking_list

Private function accessible through /booking GET 
It returns every booking of every resource. 

=cut

sub booking_list : Private {
    my ( $self, $c ) = @_;

    my @booking_aux = $c->model('DB::TBooking')->all;
    my @booking;
    my @bookings;

    foreach (@booking_aux) {
        @booking = $_->hash_booking;
        push( @bookings, @booking );
    }

    $c->stash->{content}  = \@bookings;
    $c->stash->{bookings} = \@bookings;
    my @events = $c->model('DB::TEvent')->all;
    $c->stash->{events} = \@events;
    my @resources = $c->model('DB::TResource')->all;
    $c->stash->{resources} = \@resources;
    $c->stash->{content}   = \@bookings;
    $c->stash->{bookings}  = \@bookings;
    $c->response->status(200);
    $c->stash->{template} = 'booking/get_list.tt';

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

    my @booking_aux
        = $c->model('DB::TBooking')->search( { id_resource => $id } );

    my @booking;
    my @bookings;

# hash_booking is a function implemented in Schema/Result/Booking.pm it makes the booking easier
# to handle

    foreach (@booking_aux) {
        @booking = $_->hash_booking;
        push( @bookings, @booking );
    }

#Whatever is put inside $c->stash->{content} is encoded to JSON, if that's the view requested
    $c->stash->{content} = \@bookings;

#The HTML view uses $c->stash->{booking} because it makes clearer and more understandable the TT
#templates
    $c->stash->{bookings} = \@bookings;

#Events and Resources are passed to the HTML view in order to build the select menus
    my @events = $c->model('DB::TEvent')->all;
    $c->stash->{events} = \@events;
    my @resources = $c->model('DB::TResource')->all;
    $c->stash->{resources} = \@resources;

    $c->response->status(200);
    $c->stash->{template} = 'booking/get_list.tt';
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

    my @booking_aux
        = $c->model('DB::TBooking')->search( { id_event => $id } );

    my @booking;
    my @bookings;

# hash_booking is a function implemented in Schema/Result/Booking.pm it makes the booking easier
# to handle

    foreach (@booking_aux) {
        @booking = $_->hash_booking;
        push( @bookings, @booking );
    }

#Whatever is put inside $c->stash->{content} is encoded to JSON, if that's the view requested
    $c->stash->{content} = \@bookings;

#The HTML view uses $c->stash->{booking} because it makes clearer and more understandable the TT
#templates
    $c->stash->{bookings} = \@bookings;

#Events and Resources are passed to the HTML view in order to build the select menus
    my @events = $c->model('DB::TEvent')->all;
    $c->stash->{events} = \@events;
    my @resources = $c->model('DB::TResource')->all;
    $c->stash->{resources} = \@resources;

    $c->response->status(200);
    $c->stash->{template} = 'booking/get_list.tt';
}

=head2 default_POST

/booking POST
This function creates a booking for a resource and associate it to an event.

After checking that the event and the resource actually exist, we proceed to insert the booking in
the table booking of the DB if, and only if, there isn't overlapping with another previously
existing booking.

Some of the check_[....] functions are reused by other modules, so I've put them together in the
controller Check. 

check_overlap is an special case, some may suggest that it should be placed in the
Schema/Booking.pm but by doing that the only thing that we achieve is an increase of code
complexity. $c for the win!

=cut

sub default_POST {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;
    my $req = $c->request;

	if((defined $module) && ($module eq 'tag') && ($id_module)){
		$c->detach( 'post_relation_tag_booking');
	}

    my $info        = $req->parameters->{info};
    my $id_resource = $req->parameters->{id_resource};
    my $id_event    = $req->parameters->{id_event};

    my $dtstart = $req->parameters->{dtstart};
    my $dtend   = $req->parameters->{dtend};
    my $duration;

    my $exception;
    if ( $req->parameters->{exception} ) {
        my $j = JSON::Any->new;

        my $exc_aux = $j->jsonToObj( $req->parameters->{exception} );

        my ( $ex_year, $ex_month, $ex_day )
            = split( '-', $exc_aux->{exception} );
        $exception = DateTime->new(
            year  => $ex_year,
            month => $ex_month,
            day   => $ex_day
        );
    }
    
#dtstart and dtend are parsed in case that some needed parameters to build the recurrence of the
#booking aren't provided
    $dtstart  = ParseDate($dtstart);
    $dtend    = ParseDate($dtend);
    $duration = $dtend - $dtstart;

    my $freq     = $req->parameters->{frequency};
    my $interval = $req->parameters->{interval} || 1;
    my $until    = $req->parameters->{until} || $req->parameters->{dtend};

    my $by_minute = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour   = $req->parameters->{by_hour}   || $dtstart->hour;

    my $by_day = $req->parameters->{by_day};

    my $by_month     = $req->parameters->{by_month};       #$dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month};

    my $new_booking = $c->model('DB::TBooking')->find_or_new();
    
    
    $c->stash->{id_event}    = $id_event;
    $c->stash->{id_resource} = $id_resource;

    #Do the resource and the event exist?
    $c->visit( '/check/check_booking', [] );
    my $booking;

    given ($freq) {
        when ('daily') {
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

            my $booking = {
                id          => $new_booking->id,
                info        => $new_booking->info,
                id_resource => $new_booking->id_resource->id,
                id_event    => $new_booking->id_event->id,
                dtstart     => $new_booking->dtstart->iso8601(),
                dtend       => $new_booking->dtend->iso8601(),
                until       => $new_booking->until->iso8601(),
                frequency   => $new_booking->frequency,
                interval    => $new_booking->interval,
                duration    => $new_booking->duration,
                by_minute   => $new_booking->by_minute,
                by_hour     => $new_booking->by_hour,
            };
        }

        when ('weekly') {

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

            my $booking = {
                id          => $new_booking->id,
                info        => $new_booking->info,
                id_resource => $new_booking->id_resource->id,
                id_event    => $new_booking->id_event->id,
                dtstart     => $new_booking->dtstart->iso8601(),
                dtend       => $new_booking->dtend->iso8601(),
                until       => $new_booking->until->iso8601(),
                frequency   => $new_booking->frequency,
                interval    => $new_booking->interval,
                duration    => $new_booking->duration,
                by_minute   => $new_booking->by_minute,
                by_hour     => $new_booking->by_hour,
                by_day      => $new_booking->by_day,
            };

        }

        when ('monthly') {
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
                by_month     => $new_booking->by_month,
                by_day_month => $new_booking->by_day_month,
            };
        }

        default {
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

        }
    };

    $c->stash->{new_booking} = $new_booking;
    if ( $c->request->parameters->{exception} ) {
        $c->stash->{new_exception} = $exception;
    }

    $c->visit( '/check/check_overlap', [] );
    my @message;
    
    
    
    if ( $c->stash->{booking_ok} == 1 ) {
	 
        if (   $c->stash->{overlap} == 1
            or $c->stash->{empty} == 1
            or $c->stash->{too_long} == 1 )
        {
            if ( $c->stash->{empty} == 1 ) {
                @message = { message => "Bad Request", };
                $c->response->status(400);
            }
            else {
                @message
                    = { message =>
                        "Error: The booking you tried to create overlaps with another booking or with itself",
                    };
                $c->response->status(409);
            }

            $c->stash->{content} = \@message;
            $c->stash->{error}
                = "Error: Overlap with another booking or bad parameters";
            $c->stash->{template} = 'booking/get_list.tt';
        }
        else {
	    $new_booking->insert;
	    
            $c->stash->{content} = \@message;
            $c->stash->{booking} = $booking;
            $c->response->status(201);

            #$c->stash->{template} = 'booking/get_booking.tt';
            #$c->forward( 'get_booking', [ $new_booking->id ] );

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

sub post_relation_tag_booking : Private {
    my ( $self, $c) = @_;
    my @message;
     
	#TODO: operacio no permesa.
	$c->stash->{content} = \@message; 
    $c->response->status(405);
}

=head2 default_PUT

Same functionality than default_POST but updating an existing booking.

=cut

sub default_PUT {
    my ( $self, $c, $res, $id, $module, $id_module ) = @_;
    if ($id) {
		if(($module eq 'tag') && ($id_module)){
		    $c->forward( 'put_relation_tag_booking', [$id, $id_module]);
		}else{
		    $c->forward( 'put_booking', [$id] );
		}
    }
}

sub put_booking : Private {
    my ( $self, $c, $res, $id ) = @_;
    my $req = $c->request;

    my $info        = $req->parameters->{info};
    my $id_resource = $req->parameters->{id_resource};
    my $id_event    = $req->parameters->{id_event};

    my $dtstart = $req->parameters->{dtstart};
    my $dtend   = $req->parameters->{dtend};
    my $duration;

#dtstart and dtend are parsed in case that some needed parameters to build the recurrence of the
#booking aren't provided
    $dtstart  = ParseDate($dtstart);
    $dtend    = ParseDate($dtend);
    $duration = $dtend - $dtstart;

    my $freq     = $req->parameters->{frequency} || "daily";
    my $interval = $req->parameters->{interval}  || 1;
    my $until    = $req->parameters->{until}     || $req->parameters->{dtend};

    my $by_minute = $req->parameters->{by_minute} || $dtstart->minute;
    my $by_hour   = $req->parameters->{by_hour}   || $dtstart->hour;

#by_day may not be provided, so in order to build a proper ICal object, an array containing
#English day abbreviations is needed.
    my @day_abbr = ( 'mo', 'tu', 'we', 'th', 'fr', 'sa', 'su' );

    my $by_day = $req->parameters->{by_day}
        || @day_abbr[ $dtstart->day_of_week - 1 ];
    my $by_month     = $req->parameters->{by_month}     || $dtstart->month;
    my $by_day_month = $req->parameters->{by_day_month} || "";

    my $booking = $c->model('DB::TBooking')->find( { id => $id } );
    $c->stash->{id_event}    = $id_event;
    $c->stash->{id_resource} = $id_resource;

      
    #Do the resource and the event exist?
    $c->visit( '/check/check_booking', [] );

    my $jbooking;

    given ($freq) {

#Duration is saved in minuntes in the DB in order to make it easier to deal with it when the server
#builds the JSON objects
#Don't mess with the duration, the result can be weird.
        when ('daily') {
            $booking->info($info);
            $booking->id_resource($id_resource);
            $booking->id_event($id_event);
            $booking->dtstart($dtstart);
            $booking->dtend($dtend);
            $booking->duration( $duration->in_units("minutes") );
            $booking->frequency($freq);
            $booking->interval($interval);
            $booking->until($until);
            $booking->by_minute($by_minute);
            $booking->by_hour($by_hour);

            $jbooking = {
                id          => $booking->id,
                info        => $booking->info,
                id_resource => $booking->id_resource->id,
                id_event    => $booking->id_event->id,
                dtstart     => $booking->dtstart->iso8601(),
                dtend       => $booking->dtend->iso8601(),
                until       => $booking->until->iso8601(),
                frequency   => $booking->frequency,
                interval    => $booking->interval,
                duration    => $booking->duration,
                by_minute   => $booking->by_minute,
                by_hour     => $booking->by_hour,
            };
        }

        when ('weekly') {
            $booking->info($info);
            $booking->id_resource($id_resource);
            $booking->id_event($id_event);
            $booking->dtstart($dtstart);
            $booking->dtend($dtend);
            $booking->duration( $duration->in_units("minutes") );
            $booking->frequency($freq);
            $booking->interval($interval);
            $booking->until($until);
            $booking->by_minute($by_minute);
            $booking->by_hour($by_hour);
            $booking->by_day($by_day);

            $jbooking = {
                id          => $booking->id,
                info        => $booking->info,
                id_resource => $booking->id_resource->id,
                id_event    => $booking->id_event->id,
                dtstart     => $booking->dtstart->iso8601(),
                dtend       => $booking->dtend->iso8601(),
                until       => $booking->until->iso8601(),
                frequency   => $booking->frequency,
                interval    => $booking->interval,
                duration    => $booking->duration,
                by_minute   => $booking->by_minute,
                by_hour     => $booking->by_hour,
                by_day      => $booking->by_day,
            };

        }

        when ('monthly') {
            $booking->info($info);
            $booking->id_resource($id_resource);
            $booking->id_event($id_event);
            $booking->dtstart($dtstart);
            $booking->dtend($dtend);
            $booking->duration( $duration->in_units("minutes") );
            $booking->frequency($freq);
            $booking->interval($interval);
            $booking->until($until);
            $booking->by_minute($by_minute);
            $booking->by_hour($by_hour);
            $booking->by_month($by_month);
            $booking->by_day_month($by_day_month);

            $jbooking = {
                id           => $booking->id,
                info         => $booking->info,
                id_resource  => $booking->id_resource->id,
                id_event     => $booking->id_event->id,
                dtstart      => $booking->dtstart->iso8601(),
                dtend        => $booking->dtend->iso8601(),
                until        => $booking->until->iso8601(),
                frequency    => $booking->frequency,
                interval     => $booking->interval,
                duration     => $booking->duration,
                by_minute    => $booking->by_minute,
                by_hour      => $booking->by_hour,
                by_month     => $booking->by_month,
                by_day_month => $booking->by_day_month,
            };
        }

        default {
            $booking->info($info);
            $booking->id_resource($id_resource);
            $booking->id_event($id_event);
            $booking->dtstart($dtstart);
            $booking->dtend($dtend);
            $booking->duration( $duration->in_units("minutes") );
            $booking->frequency($freq);
            $booking->interval($interval);
            $booking->until($until);
            $booking->by_minute($by_minute);
            $booking->by_hour($by_hour);
            $booking->by_day($by_day);
            $booking->by_month($by_month);
            $booking->by_day_month($by_day_month);

            $jbooking = {
                id           => $booking->id,
                info         => $booking->info,
                id_resource  => $booking->id_resource->id,
                id_event     => $booking->id_event->id,
                dtstart      => $booking->dtstart->iso8601(),
                dtend        => $booking->dtend->iso8601(),
                until        => $booking->until->iso8601(),
                frequency    => $booking->frequency,
                interval     => $booking->interval,
                duration     => $booking->duration,
                by_minute    => $booking->by_minute,
                by_hour      => $booking->by_hour,
                by_day       => $booking->by_day,
                by_month     => $booking->by_month,
                by_day_month => $booking->by_day_month,
            };

        }
    };

#we are reusing /check/check_overlap that's why $booking is saved in $c->stash->{new_booking}
#For the same reason we put to true $c->stash->{PUT} so we'll be able to amply the convenient
#restrictions to the search query (see check module for details)
    $c->stash->{new_booking} = $booking;
    $c->stash->{PUT}         = 1;
    $c->visit( '/check/check_overlap', [] );


    
    if ( $c->stash->{booking_ok} == 1 ) {

        if (   $c->stash->{overlap} == 1
            or $c->stash->{empty} == 1
            or $c->stash->{too_long} == 1 )
        {
            my @message
                = { message => "Error: Bad request. Check parameters", };
            $c->stash->{content} = \@message;
            $c->response->status(409);
            $c->stash->{error}    = "Error: Bad request. Check parameters";
            $c->stash->{template} = 'booking/get_list.tt';
        }
        else {
            $booking->update;
	    
            $c->stash->{content} = $jbooking;
            $c->stash->{booking} = $jbooking;
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

sub put_relation_tag_booking : Private {
    my ( $self, $c, $id_booking , $id_module) = @_;
    my $booking = $c->model('DB::TBooking')->find( { id => $id_booking } );
    my @message;

    if ( !$booking ) {
		#TODO: message: Booking no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        $c->detach( '/tag/put_tag_object', [ $id_booking, $c->namespace, $id_module ] );
    }
}

=head2 default_DELETE

=cut

sub default_DELETE {
    my ( $self, $c, $res, $id, $module, $id_module) = @_;
    
    my $req = $c->request;
    
if ($id) {
    if(($module eq 'tag') && ($id_module)){
        $c->detach( 'delete_relation_tag_booking', [$id, $id_module]);
    }
    else {
        my $booking_aux = $c->model('DB::TBooking')->find( { id => $id } );
        my @message;
        if ($booking_aux) {
	    $booking_aux->delete;
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

sub delete_relation_tag_booking : Private {
    my ( $self, $c, $id , $id_module) = @_;
    my $booking = $c->model('DB::TBooking')->find( { id => $id } );
    my @message;

    if ( !$booking ) {
		#TODO: message: Resource no trobat.
        $c->stash->{content}  = \@message;
        
        $c->stash->{template} = 'old_not_found.tt';
        $c->response->status(404);
    }
    else {
        $c->detach( '/tag/delete_tag_from_object', [ $id, $c->namespace, $id_module ] );
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

=head2 end

The last function executed before responding the request.
Because we saved format in $c->stash->{format} it allow us to choose between the available views.

=cut

sub end : Private {
    my ( $self, $c ) = @_;

    if ( $c->stash->{ical} ) {

    }
    else {
        if ( $c->stash->{format} ne "application/json" ) {
            $c->res->content_type("text/html");
            $c->stash->{VERSION} = $VERSION;
            $c->forward( $c->view('HTML') );
        }
        else {
            $c->forward( $c->view('JSON') );
        }
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

    my @agenda_aux = $c->model('DB::TBooking')
        ->search( { id_resource => $c->stash->{id_resource} } );

    my @genda;

    foreach (@agenda_aux) {
        push( @genda, $_->hash_booking );
    }

    my $s_aux;
    my $e_aux;
    my $u_aux;
    my $set_aux;
    my @byday;
    my @bymonth;
    my @bymonthday;
    my @exrule_list;

    foreach (@genda) {
        my $vevent = Data::ICal::Entry::Event->new();
        $s_aux = ParseDate( $_->{dtstart} );
        $e_aux = ParseDate( $_->{dtend} );
        $u_aux = ParseDate( $_->{until} );

        my $f_aux = $_->{frequency};
        my $i_aux = $_->{interval};

        my $by_minute_aux = $_->{by_minute};
        my $by_hour_aux   = $_->{by_hour};

        my $by_day_aux       = $_->{byday};
        my $by_month_aux     = $_->{bymonth};
        my $by_day_month_aux = $_->{bymonthday};

        my $rrule;
        my $until = Date::ICal->new(
            year   => $u_aux->year,
            month  => $u_aux->month,
            day    => $u_aux->day,
            hour   => $u_aux->hour,
            minute => $u_aux->minute,
        );

        given ($f_aux) {
            when ('daily') {
                $rrule
                    = 'FREQ=DAILY;INTERVAL='
                    . uc($i_aux)
                    . ';UNTIL='
                    . uc( $until->ical );
            }
            when ('weekly') {
                $rrule
                    = 'FREQ=WEEKLY;INTERVAL='
                    . uc($i_aux)
                    . '.;BYDAY='
                    . uc($by_day_aux)
                    . ';UNTIL='
                    . uc( $until->ical );
            }
            when ('monthly') {
                $rrule
                    = 'FREQ=MONTHLY;INTERVAL='
                    . uc($i_aux)
                    . ';BYMONTHDAY='
                    . $by_day_month_aux
                    . ';UNTIL='
                    . uc( $until->ical );
            }
            when ('yearly') {
                $rrule
                    = 'FREQ=YEARLY;INTERVAL='
                    . uc($i_aux)
                    . ';BYMONTH='
                    . $by_month_aux
                    . ';BYMONTHDAY='
                    . $by_day_month_aux
                    . ';UNTIL='
                    . uc( $until->ical );
            }
        }

        my @exrule_list = @{ $_->{exrule_list} };

        for ( my $i = 0; $i < @exrule_list; $i++ ) {
            $vevent->add_properties( exrule => $exrule_list[$i]->{exrule} );

        }

        $vevent->add_properties(
            uid     => $_->{id},
            summary => "Booking #" . $_->{id},
            dtstart => Date::ICal->new(
                year   => $s_aux->year,
                month  => $s_aux->month,
                day    => $s_aux->day,
                hour   => $s_aux->hour,
                minute => $s_aux->minute,
                )->ical,
            dtend => Date::ICal->new(
                year   => $e_aux->year,
                month  => $e_aux->month,
                day    => $e_aux->day,
                hour   => $e_aux->hour,
                minute => $e_aux->minute,
                )->ical,
            rrule => $rrule

        );
        $calendar->add_entry($vevent);
    }

    $c->stash->{content} = \@genda;
    $c->res->content_type("text/calendar");
    $c->res->header(
        'Content-Disposition' => qq(inline; filename=$filename) );

#Due to the fact that after numbers within exrule parameters apears \ character we must parse the calendar string
#before sending it-
#s substitution
# \\ is used because we need to scape \
# \ is substituted by nothing
#g searches all matches along the string

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

    my @agenda_aux = $c->model('DB::TBooking')
        ->search( { id_event => $c->stash->{id_event} } );

    my @genda;

    foreach (@agenda_aux) {
        push( @genda, $_->hash_booking );
    }

    my $s_aux;
    my $e_aux;
    my $u_aux;
    my $set_aux;
    my @byday;
    my @bymonth;
    my @bymonthday;

    foreach (@genda) {
        my $vevent = Data::ICal::Entry::Event->new();
        $s_aux = ParseDate( $_->{dtstart} );
        $e_aux = ParseDate( $_->{dtend} );
        $u_aux = ParseDate( $_->{until} );

        my $f_aux = $_->{frequency};
        my $i_aux = $_->{interval};

        my $by_minute_aux = $_->{by_minute};
        my $by_hour_aux   = $_->{by_hour};

        my $by_day_aux       = $_->{byday};
        my $by_month_aux     = $_->{bymonth};
        my $by_day_month_aux = $_->{bymonthday};

        my $rrule;
        my $until = Date::ICal->new(
            year   => $u_aux->year,
            month  => $u_aux->month,
            day    => $u_aux->day,
            hour   => $u_aux->hour,
            minute => $u_aux->minute,
        );

        given ($f_aux) {
            when ('daily') {
                $rrule
                    = 'FREQ=DAILY;INTERVAL='
                    . uc($i_aux)
                    . ';UNTIL='
                    . uc( $until->ical );
            }
            when ('weekly') {
                $rrule
                    = 'FREQ=WEEKLY;INTERVAL='
                    . uc($i_aux)
                    . '.;BYDAY='
                    . uc($by_day_aux)
                    . ';UNTIL='
                    . uc( $until->ical );
            }
            when ('monthly') {
                $rrule
                    = 'FREQ=MONTHLY;INTERVAL='
                    . uc($i_aux)
                    . ';BYMONTHDAY='
                    . $by_day_month_aux
                    . ';UNTIL='
                    . uc( $until->ical );
            }
            when ('yearly') {
                $rrule
                    = 'FREQ=YEARLY;INTERVAL='
                    . uc($i_aux)
                    . ';BYMONTH='
                    . $by_month_aux
                    . ';BYMONTHDAY='
                    . $by_day_month_aux
                    . ';UNTIL='
                    . uc( $until->ical );
            }
        }

        my @exrule_list = @{ $_->{exrule_list} };

        for ( my $i = 0; $i < @exrule_list; $i++ ) {
            $vevent->add_properties( exrule => $exrule_list[$i]->{exrule} );

        }

        $vevent->add_properties(
            uid     => $_->{id},
            summary => "Booking #" . $_->{id},
            dtstart => uc($s_aux),
            dtend   => uc($e_aux),
            rrule   => $rrule

        );
        $calendar->add_entry($vevent);
    }

    $c->res->content_type("text/calendar");
    $c->res->header(
        'Content-Disposition' => qq(inline; filename=$filename) );

#Due to the fact that after numbers within exrule parameters apears \ character we must parse the calendar string
#before sending it-
#s substitution
# \\ is used because we need to scape \
# \ is substituted by nothing
#g searches all matches along the string

    my $calendar_ics = $calendar->as_string;
    $calendar_ics =~ s/\\//g;

    $c->res->output($calendar_ics);

}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
