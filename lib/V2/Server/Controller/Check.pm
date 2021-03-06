package V2::Server::Controller::Check;

use Moose;
use feature 'switch';

use namespace::autoclean;
use DateTime;
use DateTime::Duration;
use DateTime::Span;
use DateTime::SpanSet;
use DateTime::Event::ICal;

BEGIN { extends 'Catalyst::Controller::REST' }

=head2 check_desc check_info

This function are used to verify that the parameter name has a length
within the correct length range.

=cut

#
# FIXME: Caldria refactoritzar les funcions
#        check_desc i check_desc_resource
#
sub check_desc : Local {
    my ( $self, $c, $desc ) = @_;

    # FIXME: La API no diu enlloc que es faci aquesta conversió!!!!
    if ( defined $desc ) {
        $desc =~ s/\t//g;     #All tabs substitued by a space
        $desc =~ s/\n/ /g;    #All new lines substitued by a space
    }

    if ( length($desc) <= 128 ) {
        $c->stash->{desc_ok} = 1;
    }
    else {
        $c->stash->{desc_ok} = 0;
    }
}

sub check_desc_resource : Local {
    my ( $self, $c, $desc ) = @_;

    if ( defined $desc && length($desc) >= 1 && length($desc) <= 128 ) {

        # trim $desc to check if it consists only of blank (\s) chars
        for ($desc) {
            s/^\s+//;
            s/\s+$//;
        }
        $c->stash->{desc_ok} = length($desc) > 0 ? 1 : 0;
    }
    else {
        $c->stash->{desc_ok} = 0;
    }
}

sub check_info : Local {
    my ( $self, $c, $info ) = @_;

    if ( defined $info && length($info) <= 256 ) {
        $c->stash->{info_ok} = 1;
    }
    else {
        $c->stash->{info_ok} = 0;
    }
}

#TODO: new subroutine to check the date parameter format

sub check_date : Local {
    my ( $self, $c, $date, $atrib ) = @_;

    if ( $date =~ /\G(\d+-\d+-\d+T\d+:\d+:\d+)/ && length($date) == 19 ) {
        $c->stash->{$atrib} = 1;
    }
    else {
        $c->stash->{$atrib} = 0;
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

#Todo: New parameters to check (starts_ok) and (ends_ok)

sub check_event : Local {
    my ( $self, $c, $info, $description, $starts, $ends ) = @_;

    $c->visit( 'check_info', [$info] );
    $c->visit( 'check_desc', [$description] );
    $c->visit( 'check_date', [ $starts, 'starts_ok' ] );
    $c->visit( 'check_date', [ $ends, 'ends_ok' ] );

    if (   $c->stash->{info_ok}
        && $c->stash->{desc_ok}
        && $c->stash->{starts_ok}
        && $c->stash->{ends_ok} )
    {
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

    $c->visit( 'check_info',          [$info] );
    $c->visit( 'check_desc_resource', [$description] );

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

    my $new_booking   = $c->stash->{new_booking};
    my $new_exception = $c->stash->{new_exception};
    my $new_exc_spanSet;

    $c->stash->{overlap}  = 0;
    $c->stash->{empty}    = 0;
    $c->stash->{too_long} = 0;

    $c->stash->{set} = $c->stash->{new_booking};

    my $current_set = $c->forward( 'build_recur', [] );

    if ( $current_set->min ) {
        $c->stash->{empty} = 0;
    }
    else {
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

    my $spanSet_aux = DateTime::SpanSet->from_set_and_duration(
        set      => $current_set,
        duration => $duration
    );

    my $spanSet;

    if ( $c->stash->{new_exception} ) {
        $c->forward('build_exc');

        my $new_exc_spanSet = $c->stash->{exc_set};
        $spanSet = $spanSet_aux->complement($new_exc_spanSet);

    }
    else {
        $spanSet = $spanSet_aux->clone;
    }

    my $old_set;
    my $spanSet2;
    my $duration2;
    my $overlap;
    my @booking_aux;
    if ( $c->stash->{PUT} ) {
        my $result_set = $c->model('DB::TBooking');
        # DateTime objects must be properly formatted in search.
        # See "Formatting DateTime objects in queries" section
        # in DBIx::Class::Manual::Cookbook docs.
        my $dtf = $result_set->result_source->schema->storage->datetime_parser;
        @booking_aux = $result_set
            ->search( { id_resource => $new_booking->id_resource->id } )
            ->search( { id          => { '!=' => $new_booking->id } } )
            ->search( { until       => { '>'  => $dtf->format_datetime( $new_booking->dtstart ) } } );

    }
    else {
        @booking_aux = $c->model('DB::TBooking')
            ->search( { id_resource => $new_booking->id_resource->id } );
    }

    my @old_exceptions;

    foreach (@booking_aux) {

        $c->stash->{set} = $_;

        $old_set = $c->forward( 'build_recur', [] );

        $duration2 = DateTime::Duration->new( minutes => $_->duration, );
        $spanSet2 = DateTime::SpanSet->from_set_and_duration(
            set      => $old_set,
            duration => $duration2
        );

        my @old_exceptions = $c->model('DB::TException')
            ->search( { id_booking => $_->{id} } );
        my $count = @old_exceptions;
        my $exc_set;
        my $exc_spanSet;
        my $duration_exc;
        if ( @old_exceptions ge 1 ) {
            foreach (@old_exceptions) {

                $c->stash->{new_exception} = $old_exceptions[$count];
                $c->forward( 'build_exc', [] );

                $exc_set      = $c->stash->{exc_set};
                $duration_exc = DateTime::Duration->new(
                    minutes => $old_exceptions[$count]->duration );

                $exc_spanSet = DateTime::SpanSet->from_set_and_duration(
                    set      => $exc_set,
                    duration => $duration_exc
                );
                $spanSet2 = $spanSet2->complement($exc_spanSet);

                if   ( $count eq 0 ) { last; }
                else                 { $count--; }
            }
        }

        $overlap = $spanSet->intersects($spanSet2);

        if ($overlap) {
            $c->stash->{overlap} = 1;
            last;
        }
    }

}

sub check_exception : Local {
    my ( $self, $c ) = @_;

    my $new_exception = $c->stash->{new_exception};

    $c->stash->{empty} = 0;

    my @byday;
    my @bymonth;
    my @bymonthday;

    my $current_set;

    $c->stash->{set} = $new_exception;

    $current_set = $c->forward( 'build_recur', [] );

    if ( $current_set->min ) {
        $c->stash->{empty} = 0;
    }
    else {
        $c->stash->{empty} = 1;
    }

}

sub build_recur : Private {
    my ( $self, $c ) = @_;

    my $set = $c->stash->{set};

    my @byday;
    my @bymonth;
    my @bymonthday;

    if ( $set->by_day )   { @byday   = split( ',', $set->by_day ); }
    if ( $set->by_month ) { @bymonth = split( ',', $set->by_month ); }
    if ( $set->by_day_month ) {
        @bymonthday = split( ',', $set->by_day_month );
    }

    my @recur =  (
        dtstart  => $set->dtstart,
        until    => $set->until,
        interval => $set->interval,
        byminute => $set->by_minute,
        byhour   => $set->by_hour,
    );

    my %dispatch = (
        daily => [
            freq => 'daily',
        ],

        weekly => [
                freq     => 'weekly',
                byday    => \@byday,
        ],

        monthly => [
                freq       => 'monthly',
                bymonthday => \@bymonthday,
        ],

        yearly => [
                freq       => 'yearly',
                bymonth    => \@bymonth,
                bymonthday => \@bymonthday,
        ],
    );

    my $freq = exists $dispatch{ $set->frequency } ? $set->frequency : 'yearly';
    push @recur, @{ $dispatch{$freq} };

    my $recur = DateTime::Event::ICal->recur(@recur);
    return $recur;
}

sub build_exc : Private {
    my ( $self, $c ) = @_;

    my $set = $c->stash->{new_exception};

    my $dtstart = $set->clone->set( hour => 0, minute => 0, second => 0 );
    my $dtend = $dtstart->clone->add( days => 1 );

    my $exc_set_aux
        = DateTime::Span->from_datetimes( start => $dtstart, end => $dtend );

    my $exc_set = DateTime::SpanSet->from_spans( spans => [$exc_set_aux] );

    $c->stash->{exc_set} = $exc_set;
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

