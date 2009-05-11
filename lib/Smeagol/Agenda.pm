package Smeagol::Agenda;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
use XML::LibXML;
use Smeagol::Booking;
use Smeagol::XML;
use Carp;

use overload q{""} => \&__str__;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
    return $obj;
}

sub append {
    my $self = shift;
    my ($slot) = @_;

    croak "Agenda->append requires one parameter"
        unless defined $slot;

    $self->insert($slot) unless $self->interlace($slot);
}

sub interlace {
    my $self = shift;
    my ($slot) = @_;

    croak "Agenda->interlace requires one parameter"
        unless defined $slot;

    return grep { $slot->intersects($_) } $self->elements;
}

sub __str__ {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $xmlText = "<agenda>";
    for my $slot ( $self->elements ) {
        $xmlText .= $slot->to_xml($url);
    }
    $xmlText .= "</agenda>";

    return $xmlText
        unless defined $url;

    my $xmlDoc = eval { Smeagol::XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "agenda", $url . "/bookings" );
    if ($isRootNode) {
        $xmlDoc->addPreamble("agenda");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("agenda")->[0];
        return $node->toString;
    }
}

# DEPRECATED
sub to_xml {
    return shift->__str__(@_);
}

sub from_xml {
    my $class = shift;
    my ($xml) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Agenda DTD v0.03",
        "share/dtd/agenda.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
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
        my $b = Smeagol::Booking->from_xml( $booking_dom_node->toString(0) );
        $ag->append($b);
    }

    return $ag;
}

sub ical {
    my $self = shift;

    my $class = __PACKAGE__ . "::ICal";

    for my $elem ( $self->elements ) {
        $self->remove($elem);
        $self->append( $elem->ical );
    }

    eval "require $class";
    return bless $self, $class;
}

1;
