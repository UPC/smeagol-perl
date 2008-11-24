package Booking;

use DateTime::Span ();
use XML::Simple;
use XML::LibXML;
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

    my $xml =
        "<booking><from>".
            "<year>"   .   $from->year  . "</year>".
            "<month>"  .  $from->month  . "</month>".
            "<day>"    .    $from->day  . "</day>".
            "<hour>"   .   $from->hour  . "</hour>".
            "<minute>" . $from->minute  . "</minute>".
            "<second>" . $from->second  . "</second>".
        "</from><to>"  .
            "<year>"   .   $to->year    . "</year>".
            "<month>"  .   $to->month   . "</month>".
            "<day>"    .    $to->day    . "</day>".
            "<hour>"   .   $to->hour    . "</hour>".
            "<minute>" . $to->minute    . "</minute>".
            "<second>" . $to->second    . "</second>".
        "</to></booking>";

    return $xml;
}


sub from_xml {
    my $class = shift;
    my $xml = shift;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new(
        "CPL UPC//Resource DTD v0.01",
        "http://devel.cpl.upc.edu/recursos/export/HEAD/angel/xml/booking.dtd");

    my $doc = XML::LibXML->new->parse_string($xml);

    if (!$doc->is_valid($dtd)) {
        # Validation failed
        return 0;
    }

    # XML is valid.
    my $b = XMLin($xml);

    my $obj = $class->SUPER::from_datetimes(
                start=> DateTime->new(
                    year   => $b->{from}->{year}, 
                    month  => $b->{from}->{month}, 
                    day    => $b->{from}->{day}, 
                    hour   => $b->{from}->{hour}, 
                    minute => $b->{from}->{minute}, 
                    second => $b->{from}->{second} 
                    ), 
                end => DateTime->new(
                    year   => $b->{to}->{year}, 
                    month  => $b->{to}->{month}, 
                    day    => $b->{to}->{day}, 
                    hour   => $b->{to}->{hour}, 
                    minute => $b->{to}->{minute}, 
                    second => $b->{to}->{second} 
                    )
                );

    bless $obj, $class;
}

1;
