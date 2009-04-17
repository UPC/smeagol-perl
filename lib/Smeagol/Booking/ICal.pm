package Smeagol::Booking::ICal;

use strict;
use warnings;

use base qw(Smeagol::Booking);

use overload q{""} => \&__str__;

use Date::ICal;
use Data::ICal::Entry::Event;
use Data::ICal;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new(@_);

    bless $obj, $class;
    return $obj;
}

sub parent {
    my $self = shift;

    my $class = "Smeagol::Booking";
    return bless $self, $class;
}

sub event {
    my $self = shift;

    my $from = $self->start;
    my $to   = $self->end;

    my $event = Data::ICal::Entry::Event->new();
    $event->add_properties(
        summary => $self->description,
        dtstart => Date::ICal->new(
            year  => $from->year,
            month => $from->month,
            day   => $from->day,
            hour  => $from->hour,
            min   => $from->minute,
            sec   => $from->second,
            )->ical,
        dtend => Date::ICal->new(
            year  => $to->year,
            month => $to->month,
            day   => $to->day,
            hour  => $to->hour,
            min   => $to->minute,
            sec   => $to->second,
            )->ical,
    );

    return $event;
}

sub calendar {
    my $self = shift;

    my $agenda = Data::ICal->new();
    $agenda->add_entry( $self->event );
    return $agenda;
}

sub __str__ {
    my $self = shift;

    return $self->event->as_string;
}

1;
