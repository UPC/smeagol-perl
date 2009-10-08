package Smeagol::Booking;

use strict;
use warnings;

use DateTime::Span ();
use Carp;
use Smeagol::XML;
use Smeagol::DataStore;
use base qw(DateTime::SpanSet);

use overload
    q{""} => \&toString,
    q{==} => \&isEqual,
    q{eq} => \&isEqual,
    q{!=} => \&isNotEqual,
    q{ne} => \&isNotEqual;

sub new {
    my $class = shift;
    my ( $description, $from, $to, $info ) = @_;

    return if ( !defined($description) || !defined($from) || !defined($to) );

    my $span = DateTime::Span->from_datetimes(
        start => $from,
        end   => $to,
    );
    my $obj = $class->SUPER::from_spans( spans => [$span], );

    $obj->{ __PACKAGE__ . "::description" } = $description;
    $obj->{ __PACKAGE__ . "::id" }
        = Smeagol::DataStore->getNextID(__PACKAGE__);
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

sub isEqual {
    my $self = shift;
    my ($booking) = @_;

    croak "invalid reference"
        unless ref($booking) eq __PACKAGE__;

    return
           $self->description eq $booking->description
        && $self->contains($booking)
        && $booking->contains($self)
        && $self->info eq $booking->info;
}

sub isNotEqual {
    return !shift->isEqual(@_);
}

# Returns an Smeagol::XML object representing the Booking
# The following method is useful when building DOMs from wrapper
# classes (agenda, resource), which can call toSmeagolXML() without
# having to call toString and parse the result again.
sub toSmeagolXML {
    my $self        = shift;
    my $xlinkPrefix = shift;

    my $from = $self->span->start;
    my $to   = $self->span->end;

    my $result = eval { Smeagol::XML->new('<booking/>') };
    croak $@ if $@;

    my $dom         = $result->doc;
    my $bookingNode = $dom->documentElement();

    my $fromNode = $dom->createElement('from');
    $fromNode->appendTextChild( 'year',   $from->year );
    $fromNode->appendTextChild( 'month',  $from->month );
    $fromNode->appendTextChild( 'day',    $from->day );
    $fromNode->appendTextChild( 'hour',   $from->hour );
    $fromNode->appendTextChild( 'minute', $from->minute );
    $fromNode->appendTextChild( 'second', $from->second );

    my $toNode = $dom->createElement('to');
    $toNode->appendTextChild( 'year',   $to->year );
    $toNode->appendTextChild( 'month',  $to->month );
    $toNode->appendTextChild( 'day',    $to->day );
    $toNode->appendTextChild( 'hour',   $to->hour );
    $toNode->appendTextChild( 'minute', $to->minute );
    $toNode->appendTextChild( 'second', $to->second );

    $bookingNode->appendTextChild( 'id',          $self->id );
    $bookingNode->appendTextChild( 'description', $self->description );
    $bookingNode->appendChild($fromNode);
    $bookingNode->appendChild($toNode);
    $bookingNode->appendTextChild( 'info', $self->info );

    if ( defined $xlinkPrefix ) {
        $result->addXLink( "booking", $xlinkPrefix . $self->url );
    }

    return $result;
}

sub toString {
    my $self = shift;
    my $url  = shift;

    my $xmlBooking = $self->toSmeagolXML($url);

    return $xmlBooking->toString;
}

# DEPRECATED
sub toXML {
    return shift->toString(@_);
}

sub newFromXML {
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

    # $doc won't be modified, so we can speed up XPath
    # searches with indexElements()
    $doc->indexElements();

    my $span = DateTime::Span->from_datetimes(
        start => DateTime->new(
            year   => $doc->findvalue('/booking/from/year'),
            month  => $doc->findvalue('/booking/from/month'),
            day    => $doc->findvalue('/booking/from/day'),
            hour   => $doc->findvalue('/booking/from/hour'),
            minute => $doc->findvalue('/booking/from/minute'),
            second => $doc->findvalue('/booking/from/second'),
        ),
        end => DateTime->new(
            year   => $doc->findvalue('/booking/to/year'),
            month  => $doc->findvalue('/booking/to/month'),
            day    => $doc->findvalue('/booking/to/day'),
            hour   => $doc->findvalue('/booking/to/hour'),
            minute => $doc->findvalue('/booking/to/minute'),
            second => $doc->findvalue('/booking/to/second'),
        )
    );

    my $obj = $class->SUPER::from_spans( spans => [$span], );

    $obj->{ __PACKAGE__ . "::id" }
        = ( $doc->exists('/booking/id') ) ? $doc->findvalue('/booking/id')
        : ( defined $id ) ? $id
        :                   Smeagol::DataStore->getNextID(__PACKAGE__);

    $obj->{ __PACKAGE__ . "::description" }
        = $doc->findvalue('/booking/description');
    $obj->{ __PACKAGE__ . "::info" }
        = $doc->exists('/booking/info')
        ? $doc->findvalue('/booking/info')
        : '';

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
