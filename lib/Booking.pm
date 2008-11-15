package Booking;

use DateTime::Span ();
use base qw(DateTime::Span);

use overload
    q{""} => \&__str__,
    q{==} => \&__equal__,
    q{!=} => \&__not_equal__;

sub new {
    my $class = shift;
    my ($from, $to) = @_;

    my $obj = $class->SUPER::from_datetimes(
        start => $from,
        end   => $to,
    );
    
    bless $obj, $class;
}

sub __str__ {
    my $self = shift;

    my $from = $self->start;
    my $to   = $self->end;

    return "<$from,$to>";
}

sub __equal__ {
    my $self = shift;
    my ($booking) = @_;

    return $self->start == $booking->start
        && $self->end   == $booking->end;
}

sub __not_equal__ {
    return !shift->__equal__(@_);
}

sub to_xml {
    my $self = shift;

    my $from = $self->start;
    my $to   = $self->end;

    my $xml = "<booking><from>$from</from><to>$to</to></booking>";
	return $xml;
}

1;
