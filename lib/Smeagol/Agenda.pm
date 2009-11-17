package Smeagol::Agenda;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
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

sub toSmeagolXML {
    my $self        = shift;
    my $xlinkPrefix = shift;

    my $url;
    $url = ( $xlinkPrefix . $self->url ) if defined $xlinkPrefix;

    my $result = eval { Smeagol::XML->new("<agenda/>") };
    croak $@ if $@;

    my $agendaNode = $result->doc->documentElement();

    for my $slot ( $self->elements ) {
        my $bookingNode
            = $slot->toSmeagolXML($xlinkPrefix)->doc->documentElement();
        $result->doc->adoptNode($bookingNode);
        $agendaNode->appendChild($bookingNode);
    }

    $result->addXLink( "agenda", $url ) if defined $xlinkPrefix;

    return $result;
}

# no special order is granted in results, because of Set->elements behaviour.
sub toString {
    my $self = shift;
    my $url  = shift;

    my $xmlAgenda = $self->toSmeagolXML($url);

    return $xmlAgenda->toString;
}

# DEPRECATED
sub toXML {
    return shift->toString(@_);
}

sub url {
    return "/bookings";
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
        my $booking = Smeagol::Booking->newFromXML( $node->toString );
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
