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

    $c->stash->{set} = $new_booking;
    
    my $current_set = $c->forward('build_recur', [] );
    
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

    my @old_exceptions;

    foreach (@booking_aux) {
        $c->log->debug( "Checking Booking #" . $_->id );
	$c->log->debug("Duration (in minutes)".$_->duration);

	$c->stash->{set} = $_;
	
	$old_set = $c->forward('build_recur', [] );

        $duration2 = DateTime::Duration->new( minutes => $_->duration, );
        $spanSet2 = DateTime::SpanSet->from_set_and_duration(
            set      => $old_set,
            duration => $duration2
        );
	
	my @old_exceptions = $c->model('DB::TException')->search({id_booking => $_->{id}});
	my $count = @old_exceptions;
	my $exc_set;
	my $exc_spanSet;
	my $duration_exc;
	if (@old_exceptions ge 1){
	  foreach (@old_exceptions) {
	    $c->log->debug("EXCP: ".Dumper($old_exceptions[$count]));
	    $exc_set = $c->forward('build_recur', [$old_exceptions[$count]]);
	    $duration_exc = DateTime::Duration->new( minutes => $old_exceptions[$count]->duration );;
	    
	    $exc_spanSet = DateTime::SpanSet->from_set_and_duration(
	      set      => $exc_set,
	      duration => $duration_exc
	    );
	    $spanSet2 = $spanSet2->complement($exc_spanSet);
	    
	    if ($count eq 0) {last;}else{$count--;}
	  }
	}

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
    
    $c->stash->{set} = $new_exception;
    
    $current_set = $c->forward('build_recur', [] );

    if ( $current_set->min ) {
        $c->stash->{empty} = 0;
    }
    else {
        $c->stash->{empty} = 1;
    }

}

sub build_recur :Private {
  my ($self, $c) =@_;
  
  my $set = $c->stash->{set};

  my $recur;
  my @byday;
  my @bymonth;
  my @bymonthday;
  
  if ( $set->by_day )   { @byday   = split( ',', $set->by_day ); }
  if ( $set->by_month ) { @bymonth = split( ',', $set->by_month ); }
  if ( $set->by_day_month ) {
     @bymonthday = split( ',', $set->by_day_month );
  }
  
  given ( $set->frequency ) {
        when ('daily') {
            $recur = DateTime::Event::ICal->recur(
                dtstart  => $set->dtstart,
                dtend    => $set->dtend,
                until    => $set->until,
                freq     => 'daily',
                interval => $set->interval,
                byminute => $set->by_minute,
                byhour   => $set->by_hour,
            );
        }

        when ('weekly') {
            @byday = split( ',', $set->by_day );
            $recur = DateTime::Event::ICal->recur(
                dtstart  => $set->dtstart,
                dtend    => $set->dtend,
                until    => $set->until,
                freq     => 'weekly',
                interval => $set->interval,
                byminute => $set->by_minute,
                byhour   => $set->by_hour,
                byday    => \@byday,
            );
        }

        when ('monthly') {
            @bymonthday = split( ',', $set->by_day_month );

            $recur = DateTime::Event::ICal->recur(
                dtstart    => $set->dtstart,
                dtend      => $set->dtend,
                until      => $set->until,
                freq       => 'monthly',
                interval   => $set->interval,
                byminute   => $set->by_minute,
                byhour     => $set->by_hour,
                bymonthday => \@bymonthday
            );
        }

        default {
            @bymonth    = split( ',', $set->by_month );
            @bymonthday = split( ',', $set->by_day_month );

            $recur = DateTime::Event::ICal->recur(
                dtstart    => $set->dtstart,
                dtend      => $set->dtend,
                until      => $set->until,
                freq       => 'yearly',
                interval   => $set->interval,
                byminute   => $set->by_minute,
                byhour     => $set->by_hour,
                bymonth    => \@bymonth,
                bymonthday => \@bymonthday
            );
        }
    };
    
    return $recur;
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
