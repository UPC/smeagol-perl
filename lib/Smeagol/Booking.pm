package Smeagol::Booking;

use strict;
use warnings;

use DateTime::Span ();
use XML::Simple;
use XML::LibXML;
use Carp;
use Smeagol::XML;
use Smeagol::DataStore;
use base qw(DateTime::Span);

use overload
    q{""} => \&__str__,
    q{==} => \&__equal__,
    q{eq} => \&__equal__,
    q{!=} => \&__not_equal__,
    q{ne} => \&__not_equal__;

sub new {
    my $class = shift;
    my ( $description, $from, $to, $info ) = @_;

    return if ( !defined($description) || !defined($from) || !defined($to) );

    my $obj = $class->SUPER::from_datetimes(
        start => $from,
        end   => $to,
    );

    $obj->{ __PACKAGE__ . "::description" } = $description;
    $obj->{ __PACKAGE__ . "::id" } = Smeagol::DataStore->next_id(__PACKAGE__);
    $obj->{ __PACKAGE__ . "::info" } = defined($info) ? $info : '';

    bless $obj, $class;
    return $obj;
}

sub id {
    my $self = shift;

    my $field = __PACKAGE__ . "::id";
    if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

sub description {
    my $self = shift;

    my $field = __PACKAGE__ . "::description";
    if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

sub info {
    my $self = shift;

    my $field = __PACKAGE__ . "::info";
    if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

sub url {
    my $self = shift;

    return "/booking/" . $self->id;
}

sub __equal__ {
    my $self = shift;
    my ($booking) = @_;

    croak "invalid reference"
        unless ref($booking) eq __PACKAGE__;

    return
           $self->description eq $booking->description
        && $self->start == $booking->start
        && $self->end == $booking->end
        && $self->info eq $booking->info;
}

sub __not_equal__ {
    return !shift->__equal__(@_);
}

sub __str__ {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $from = $self->start;
    my $to   = $self->end;

    my $xmlText
        = "<booking>" . "<id>"
        . $self->id . "</id>"
        . "<description>"
        . $self->description
        . "</description>"
        . "<from>"
        . "<year>"
        . $from->year
        . "</year>"
        . "<month>"
        . $from->month
        . "</month>" . "<day>"
        . $from->day
        . "</day>"
        . "<hour>"
        . $from->hour
        . "</hour>"
        . "<minute>"
        . $from->minute
        . "</minute>"
        . "<second>"
        . $from->second
        . "</second>"
        . "</from><to>"
        . "<year>"
        . $to->year
        . "</year>"
        . "<month>"
        . $to->month
        . "</month>" . "<day>"
        . $to->day
        . "</day>"
        . "<hour>"
        . $to->hour
        . "</hour>"
        . "<minute>"
        . $to->minute
        . "</minute>"
        . "<second>"
        . $to->second
        . "</second>" . "</to>"
        . "<info>"
        . $self->info
        . "</info>"
        . "</booking>";

    return $xmlText
        unless defined $url;

    my $xmlDoc = eval { Smeagol::XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "booking", $url . $self->url );
    if ($isRootNode) {
        $xmlDoc->addPreamble("booking");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("booking")->[0];
        return $node->toString;
    }

}

# DEPRECATED
sub to_xml {
    return shift->__str__(@_);
}

sub from_xml {
    my $class = shift;
    my ( $xml, $id ) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Booking DTD v0.03",
        "dtd/booking.dtd" );

    my $doc = eval { XML::LibXML->new->parse_string($xml) };
    croak $@ if $@;

    if ( ( !defined $doc ) || !$doc->is_valid($dtd) ) {

        # Validation failed
        return;
    }

    # XML is valid. Build empty elements as ''
    my $b = XMLin( $xml, SuppressEmpty => '' );

    my $obj = $class->SUPER::from_datetimes(
        start => DateTime->new(
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

    $obj->{ __PACKAGE__ . "::id" }
        = ( defined $b->{id} ) ? $b->{id}
        : ( defined $id ) ? $id
        :                   Smeagol::DataStore->next_id(__PACKAGE__);

    $obj->{ __PACKAGE__ . "::description" } = $b->{description};
    $obj->{ __PACKAGE__ . "::info" }
        = defined( $b->{info} ) ? $b->{info} : '';

    bless $obj, $class;
    return $obj;
}

sub ical {
    my $self = shift;

    my $class = __PACKAGE__ . "::ICal";

    eval "require $class";
    return bless $self, $class;
}

1;
