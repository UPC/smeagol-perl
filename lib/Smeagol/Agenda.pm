package Smeagol::Agenda;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
use XML::LibXML;
use Smeagol::Booking;
use Smeagol::XML;
use Carp;

use overload q{""} => \&toString;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
    return $obj;
}

sub append {
    my $self = shift;
    my ($booking) = @_;

    croak "Agenda->append requires one parameter"
        unless defined $booking;

    $self->insert($booking) unless $self->interlace($booking);
}

sub interlace {
    my $self = shift;
    my ($booking) = @_;

    croak "Agenda->interlace requires one parameter"
        unless defined $booking;

    return grep { $booking->intersects($_) } $self->elements;
}

# no special order is granted in results, because of Set->elements behaviour.
sub toString {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    # build XML document
    my $dom = XML::LibXML::Document->new('1.0','UTF-8');
    my $agendaNode = $dom->createElement('agenda');
    $dom->setDocumentElement( $agendaNode );

    for my $slot ( $self->elements ) {
        my $bookingNode = $slot->toDOM->documentElement();
        $dom->adoptNode( $bookingNode );
        $agendaNode->appendChild( $bookingNode );
    }

    my $xmlText = $dom->toString;

    return $xmlText unless defined $url;

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
sub toXML {
    return shift->toString(@_);
}

sub newFromXML {
    my $class = shift;
    my ($xml) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Agenda DTD v0.03",
        "dtd/agenda.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
    }

    # at this point, we are certain that $xml was a valid XML
    # representation of an Agenda object; that is,
    # $dom variable contains a DOM (Document Object Model)
    # representation of the $xml string

    my $agenda = $class->SUPER::new();
    bless $agenda, $class;

    # traverse all '<booking>' elements found in DOM structure.
    # note: all intersecting bookings in the agenda will be ignored,
    # because we use the "append" method to store bookings in the
    # $ag object, so we do not need to worry about eventual
    # intersections present in the $xml
    for my $node ( $dom->getElementsByTagName('booking') ) {
        my $booking = Smeagol::Booking->newFromXML( $node->toString(0) );
        $agenda->append($booking);
    }

    return $agenda;
}

# no special order is granted in results, because of Set->elements behaviour.
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
