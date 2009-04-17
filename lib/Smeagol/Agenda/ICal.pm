package Smeagol::Agenda::ICal;

use strict;
use warnings;

use base qw(Smeagol::Agenda);

use Data::ICal;

use overload q{""} => \&__str__;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new(@_);

    bless $obj, $class;
    return $obj;
}

sub parent {
    my $self = shift;

    my $class = "Smeagol::Agenda";
    return bless $self, $class;
}

sub __str__ {
    my $self = shift;

    my $iCal = Data::ICal->new();
    for my $entry ( $self->elements ) {
        $iCal->add_entry( $entry->event );
    }

    return $iCal->as_string;
}

1;
