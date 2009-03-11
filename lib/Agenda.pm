package Agenda;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
use XML::LibXML;
use Booking;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
}

sub append {
    my $self = shift;
    my ($slot) = @_;

    ( defined $slot ) or die "Agenda->append requires one parameter";

    $self->insert($slot) unless $self->interlace($slot);
}

sub interlace {
    my $self = shift;
    my ($slot) = @_;

    ( defined $slot ) or die "Agenda->interlace requires one parameter";
    return grep { $slot->intersects($_) } $self->elements;
}

sub to_xml {
    my $self = shift;

    my $xml = "<agenda>";

    for my $slot ( $self->elements ) {
        $xml .= $slot->to_xml();
    }
    $xml .= "</agenda>";

    return $xml;
}

sub from_xml {
    my $class = shift;
    my $xml   = shift;

    # validate XML string against the DTD
    my $dtd =
      XML::LibXML::Dtd->new( "CPL UPC//Agenda DTD v0.01", "dtd/agenda.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return undef;
    }

    # at this point, we are certain that $xml was a valid XML
    # representation of an Agenda object; that is,
    # $dom variable contains a DOM (Document Object Model)
    # representation of the $xml string

    my $ag = $class->SUPER::new();
    bless $ag, $class;

    # traverse all '<booking>' elements found in DOM structure.
    # note: all intersecting bookings in the agenda will be ignored,
    # because we use the "append" method to store bookings in the
    # $ag object, so we do not need to worry about eventual
    # intersections present in the $xml
    for my $booking_dom_node ( $dom->getElementsByTagName('booking') ) {
        my $b = Booking->from_xml( $booking_dom_node->toString(0) );
        $ag->append($b);
    }

    return $ag;
}

1;
