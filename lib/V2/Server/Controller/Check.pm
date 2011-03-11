package V2::Server::Controller::Check;

use Moose;
use feature 'switch';

use namespace::autoclean;
use Data::Dumper;
use DateTime;
use DateTime::Duration;
use DateTime::SpanSet;
use DateTime::Event::ICal;

BEGIN { extends 'Catalyst::Controller::REST' }

=head2 check_name check_desc check_info
This function are used to verify that the parameter name has a lenght within 
the correct length range.
=cut

sub check_name : Local {
    my ( $self, $c, $name ) = @_;

    if ( length($name) < 64 && length($name) > 3 ) {
        $c->stash->{name_ok} = 1;
    }
    else {
        $c->stash->{name_ok} = 0;
    }

}

sub check_desc : Local {
    my ( $self, $c, $desc ) = @_;

    $desc =~ s/\t//g; #All tabs substitued by a space 
    $desc =~ s/\n/ /g; #All new lines substitued by a space

    if ( length($desc) < 128 && $desc =~ m/\S+[A-Z]|[a-z]/) {
        $c->log->debug("Descr OK");
        $c->stash->{desc_ok} = 1;
    }
    else {
        $c->log->debug("Descr KO");
        $c->stash->{desc_ok} = 0;
    }
}

sub check_desc_tag : Local {
    my ( $self, $c, $desc ) = @_;

    if ( length($desc) < 256 ) {
        $c->log->debug("Descr OK");
        $c->stash->{desc_ok} = 1;
    }
    else {
        $c->log->debug("Descr KO");
        $c->stash->{desc_ok} = 0;
    }
}

sub check_info : Local {
    my ( $self, $c, $info ) = @_;

    if ( length($info) < 256 ) {
        $c->stash->{info_ok} = 1;
    }
    else {
        $c->stash->{info_ok} = 0;
    }
}

=head2 check_booking
We verify that the resource exists and that the booking will be associated with an existing event.
If one of these two conditions isn't not fullfiled, the booking can't be made.
=cut

sub check_booking : Local {
    my ( $self, $c ) = @_;
    my $id_resource = $c->stash->{id_resource};
    my $id_event    = $c->stash->{id_event};

    $c->log->debug( "Check booking. ID resource: " . $id_resource );
    $c->log->debug( "Check booking. ID event: " . $id_event );

    my $resource = $c->model('DB::TResource')->find( { id => $id_resource } );
    my $event = $c->model('DB::TEvent')->find( { id => $id_event } );

    if ( $resource && $event ) {
        $c->stash->{booking_ok} = 1;
    }
    else {
        $c->stash->{booking_ok} = 0;
    }

}

=head2 check_event
Function used to verify that event parameters are within the proper range 
=cut

sub check_event : Local {
    my ( $self, $c, $info, $description ) = @_;

    $c->visit( 'check_info', [$info] );
    $c->visit( 'check_desc', [$description] );

    if ( $c->stash->{info_ok} && $c->stash->{desc_ok} ) {
        $c->stash->{event_ok} = 1;
    }
    else {
        $c->stash->{event_ok} = 0;
    }
}

=head2 check_resource
Function used to verify that resource parameters are within the proper range 
=cut

sub check_resource : Local {
    my ( $self, $c, $info, $description ) = @_;

    $c->visit( 'check_info', [$info] );
    $c->visit( 'check_desc', [$description] );

    if ( $c->stash->{info_ok} && $c->stash->{desc_ok} ) {
        $c->stash->{resource_ok} = 1;
    }
    else {
        $c->stash->{resource_ok} = 0;
    }
}

=head2 check_overlap
With the parameters from the current request we build firstly a DateTime::Event::Ical and secondly
using the duration parameter we obtain $spanSet (a DateTime::SpanSet which we can check if it
intersecs with the existing ones).

Once we have $spanSet, the process previously explained is repeated for each one of the existing
bookings of the resource. If there isn't any overlap: OK. If there is overlap the booking will not
be inserted in the DB.
=cut

sub check_overlap : Local {
    my ( $self, $c ) = @_;

    my $new_booking            = $c->stash->{new_booking};
    my @new_booking_exceptions = $c->stash->{new_booking_exceptions};

    $c->log->debug("Provant si hi ha solapament");
    $c->stash->{overlap}  = 0;
    $c->stash->{empty}    = 0;
    $c->stash->{too_long} = 0;

    my @byday;
    my @bymonth;
    my @bymonthday;

    my $current_set;

    given ( $new_booking->frequency ) {
        when ('daily') {
            $current_set = DateTime::Event::ICal->recur(
                dtstart  => $new_booking->dtstart,
                dtend    => $new_booking->dtend,
                until    => $new_booking->until,
                freq     => 'daily',
                interval => $new_booking->interval,
                byminute => $new_booking->by_minute,
                byhour   => $new_booking->by_hour,
            );
        }

        when ('weekly') {
            @byday = split( ',', $new_booking->by_day );
            $current_set = DateTime::Event::ICal->recur(
                dtstart  => $new_booking->dtstart,
                dtend    => $new_booking->dtend,
                until    => $new_booking->until,
                freq     => 'weekly',
                interval => $new_booking->interval,
                byminute => $new_booking->by_minute,
                byhour   => $new_booking->by_hour,
                byday    => \@byday,
            );
        }

        when ('monthly') {
            @bymonthday = split( ',', $new_booking->by_day_month );

            $current_set = DateTime::Event::ICal->recur(
                dtstart    => $new_booking->dtstart,
                dtend      => $new_booking->dtend,
                until      => $new_booking->until,
                freq       => 'monthly',
                interval   => $new_booking->interval,
                byminute   => $new_booking->by_minute,
                byhour     => $new_booking->by_hour,
                bymonthday => \@bymonthday
            );
        }

        default {
            @bymonth    = split( ',', $new_booking->by_month );
            @bymonthday = split( ',', $new_booking->by_day_month );

            $current_set = DateTime::Event::ICal->recur(
                dtstart    => $new_booking->dtstart,
                dtend      => $new_booking->dtend,
                until      => $new_booking->until,
                freq       => 'yearly',
                interval   => $new_booking->interval,
                byminute   => $new_booking->by_minute,
                byhour     => $new_booking->by_hour,
                bymonth    => \@bymonth,
                bymonthday => \@bymonthday
            );
        }
    };

    if ( $current_set->min ) {
        $c->log->debug("L'SpanSet té com a mínim un element");
        $c->stash->{empty} = 0;
    }
    else {
        $c->log->debug("L'SpanSet està buit!");
        $c->stash->{empty} = 1;
    }

    my $duration
        = DateTime::Duration->new( minutes => $new_booking->duration, );

    # $duration should be shorter than 1 day.
    # Otherwise there will be bookings overlapping with themselves
    # wich is kind of weird.

    if ( $duration->in_units('days') ge 1 ) {
        $c->stash->{too_long} = 1;
    }

    $c->log->debug(
        "Duració nova reserva:
  " . $duration->hours . "h" . $duration->minutes . "min"
    );

    my $spanSet = DateTime::SpanSet->from_set_and_duration(
        set      => $current_set,
        duration => $duration
    );

    my $old_set;
    my $spanSet2;
    my $duration2;
    my $overlap;
    my @booking_aux;
    if ( $c->stash->{PUT} ) {
        @booking_aux
            = $c->model('DB::TBooking')
            ->search( { id_resource => $new_booking->id_resource->id } )
            ->search( { id          => { '!=' => $new_booking->id } } )
            ->search( { until       => { '>' => $new_booking->dtstart } } );

    }
    else {
        @booking_aux = $c->model('DB::TBooking')
            ->search( { id_resource => $new_booking->id_resource->id } );
    }

    $c->log->debug( "Hi ha "
            . @booking_aux
            . " que compleixen els criteris de la cerca" );

    my $dtstart;
    my $dtend;
    my $until;
    my $frequency;
    my $interval;
    my $byminute;
    my $byhour;

    foreach (@booking_aux) {
        $c->log->debug( "Checking Booking #" . $_->id );

        if ( $_->by_day )   { @byday   = split( ',', $_->by_day ) }
        if ( $_->by_month ) { @bymonth = split( ',', $_->by_month ) }
        if ( $_->by_day_month ) {
            @bymonthday = split( ',', $_->by_day_month );
        }

        $dtstart   = $_->dtstart;
        $dtend     = $_->dtend;
        $until     = $_->until;
        $frequency = $_->frequency;
        $interval  = $_->interval;
        $byminute  = $_->by_minute;
        $byhour    = $_->by_hour;

        given ( $new_booking->frequency ) {
            when ('daily') {
                $old_set = DateTime::Event::ICal->recur(
                    dtstart  => $dtstart,
                    dtend    => $dtend,
                    until    => $until,
                    freq     => $frequency,
                    interval => $interval,
                    byminute => $byminute,
                    byhour   => $byhour,
                );
            }

            when ('weekly') {
                $old_set = DateTime::Event::ICal->recur(
                    dtstart  => $dtstart,
                    dtend    => $dtend,
                    until    => $until,
                    freq     => $frequency,
                    interval => $interval,
                    byminute => $byminute,
                    byhour   => $byhour,
                    byday    => \@byday,
                );
            }

            when ('monthly') {
                $old_set = DateTime::Event::ICal->recur(
                    dtstart    => $dtstart,
                    dtend      => $dtend,
                    until      => $until,
                    freq       => $frequency,
                    interval   => $interval,
                    byminute   => $byminute,
                    byhour     => $byhour,
                    bymonth    => \@bymonth,
                    bymonthday => \@bymonthday
                );
            }

            default {
                $old_set = DateTime::Event::ICal->recur(
                    dtstart    => $dtstart,
                    dtend      => $dtend,
                    until      => $until,
                    freq       => $frequency,
                    interval   => $interval,
                    byminute   => $byminute,
                    byhour     => $byhour,
                    bymonth    => \@bymonth,
                    bymonthday => \@bymonthday
                );
            }
        };

        $duration2 = DateTime::Duration->new( minutes => $_->duration );
        $spanSet2 = DateTime::SpanSet->from_set_and_duration(
            set      => $old_set,
            duration => $duration2
        );

        $overlap = $spanSet->intersects($spanSet2);

        if ($overlap) {
            $c->stash->{overlap} = 1;
            $c->log->debug("Hi ha solpament");
            last;
        }
    }

    $c->log->debug("No hi ha solpament") unless $c->stash->{overlap};

}

sub check_exception : Local {
    my ( $self, $c ) = @_;

    my $new_exception = $c->stash->{new_exception};

    $c->stash->{empty} = 0;

    my @byday;
    my @bymonth;
    my @bymonthday;

    my $current_set;

    given ( $new_exception->frequency ) {
        when ('daily') {
            $current_set = DateTime::Event::ICal->recur(
                dtstart  => $new_exception->dtstart,
                dtend    => $new_exception->dtend,
                until    => $new_exception->until,
                freq     => 'daily',
                interval => $new_exception->interval,
                byminute => $new_exception->by_minute,
                byhour   => $new_exception->by_hour,
            );
        }

        when ('weekly') {
            @byday = split( ',', $new_exception->by_day );
            $current_set = DateTime::Event::ICal->recur(
                dtstart  => $new_exception->dtstart,
                dtend    => $new_exception->dtend,
                until    => $new_exception->until,
                freq     => 'weekly',
                interval => $new_exception->interval,
                byminute => $new_exception->by_minute,
                byhour   => $new_exception->by_hour,
                byday    => \@byday,
            );
        }

        when ('monthly') {
            @bymonthday = split( ',', $new_exception->by_day_month );

            $current_set = DateTime::Event::ICal->recur(
                dtstart    => $new_exception->dtstart,
                dtend      => $new_exception->dtend,
                until      => $new_exception->until,
                freq       => 'monthly',
                interval   => $new_exception->interval,
                byminute   => $new_exception->by_minute,
                byhour     => $new_exception->by_hour,
                bymonthday => \@bymonthday
            );
        }

        default {
            @bymonth    = split( ',', $new_exception->by_month );
            @bymonthday = split( ',', $new_exception->by_day_month );

            $current_set = DateTime::Event::ICal->recur(
                dtstart    => $new_exception->dtstart,
                dtend      => $new_exception->dtend,
                until      => $new_exception->until,
                freq       => 'yearly',
                interval   => $new_exception->interval,
                byminute   => $new_exception->by_minute,
                byhour     => $new_exception->by_hour,
                bymonth    => \@bymonth,
                bymonthday => \@bymonthday
            );
        }
    };

    if ( $current_set->min ) {
        $c->log->debug("L'SpanSet té com a mínim un element");
        $c->stash->{empty} = 0;
    }
    else {
        $c->log->debug("L'SpanSet està buit!");
        $c->stash->{empty} = 1;
    }

}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
