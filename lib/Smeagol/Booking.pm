package Smeagol::Booking;

use strict;
use warnings;

use DateTime::Span ();
use XML::Simple;
use XML::LibXML;
use Carp;
use Smeagol::XML;
use Smeagol::DataStore;
use base qw(DateTime::SpanSet);
use Data::Dumper;

=head1 NAME

Smeagol::Booking - Class definition for Smeagol booking objects.

=head1 SYNOPSIS

 use Smeagol::Booking;

 my $b1 = Smeagol::Booking->new( ... );
 my $b2 = Smeagol::Booking->newFromRecurrence( ... );
 my $b3 = Smeagol::Booking->newFromXml(...);

=head1 DESCRIPTION

A Booking is simply a subclass of DateTime::SpanSet class, with a 
description and perhaps with additional information.

Bookings can be built from just a DateTime::Span, or by a set of 
DateTime::Span's defined by a recurrence as specified in RFC 2445.

=head1 USAGE

=over 4

=cut

use overload
    q{""} => \&toString,
    q{==} => \&isEqual,
    q{eq} => \&isEqual,
    q{!=} => \&isNotEqual,
    q{ne} => \&isNotEqual;

=item $booking = Smeagol::Booking->new( $description, $from, $to, $info )

Obtain a new Booking from a single DateTime::Span. The DateTime::Span 
is built from the $from and $to DateTime objects. The optional argument $info
may be used to attach additional details to the booking.

=cut

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
    $obj->{ __PACKAGE__ . "::info" }       = defined($info) ? $info : '';
    $obj->{ __PACKAGE__ . "::recurrence" } = undef;
    $obj->{ __PACKAGE__ . "::duration" }   = undef;

    bless $obj, $class;
    return $obj;
}

=item $booking = Smeagol::Booking->newFromRecurrence( $description, $info, $duration, %recurrence )

Obtain a new Booking defined by a duration and a recurrence (as specified in rfc 2445).
The $duration argument specifies the duration, in minutes, of each interval defined by recurrence.
See documentation for the "recur" method in DateTime::Event::Ical module for details about 
the %recurrence hash.

=cut

sub newFromRecurrence {
    my $class = shift;
    my ( $description, $info, $duration, %recurrence ) = @_;

    return
        unless ( ( defined $description )
        && ( defined $duration )
        && %recurrence );

    my $set = DateTime::Event::ICal->recur(%recurrence);
    my $obj = $class->SUPER::from_set_and_duration(
        set     => $set,
        minutes => $duration
    );

    $obj->{ __PACKAGE__ . "::description" } = $description;
    $obj->{ __PACKAGE__ . "::id" }
        = Smeagol::DataStore->getNextID(__PACKAGE__);
    $obj->{ __PACKAGE__ . "::info" }       = defined($info) ? $info : '';
    $obj->{ __PACKAGE__ . "::recurrence" } = \%recurrence;
    $obj->{ __PACKAGE__ . "::duration" }   = $duration;

    bless $obj, $class;
    return $obj;
}

=item $booking = Smeagol::Booking->newFromXml( $xml, $id )

Build a new Booking from its serialized representation in XML format (see Booking DTD
for additional details).
If the optional $id argument is defined, it will be assigned as the Booking ID.
Otherwise, a brand new ID will be generated and assigned to the Booking.
See Booking DTD for additional details.

=cut

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

    # XML is valid. Build empty elements as ''
    my $xmlTree = XMLin( $xml, SuppressEmpty => '', ForceArray => ['by'] );

    my $obj;
    my %recurrence;

    if ( defined $xmlTree->{from} && defined $xmlTree->{to} ) {
        my $span = DateTime::Span->from_datetimes(
            start => DateTime->new(
                year   => $xmlTree->{from}->{year},
                month  => $xmlTree->{from}->{month},
                day    => $xmlTree->{from}->{day},
                hour   => $xmlTree->{from}->{hour},
                minute => $xmlTree->{from}->{minute},
                second => $xmlTree->{from}->{second},
            ),
            end => DateTime->new(
                year   => $xmlTree->{to}->{year},
                month  => $xmlTree->{to}->{month},
                day    => $xmlTree->{to}->{day},
                hour   => $xmlTree->{to}->{hour},
                minute => $xmlTree->{to}->{minute},
                second => $xmlTree->{to}->{second},
            )
        );

        $obj = $class->SUPER::from_spans( spans => [$span], );
    }
    else {

        # Recurrent booking
        my $dtstart
            = defined $xmlTree->{recurrence}->{dtstart}
            ? DateTime->new(
            year   => $xmlTree->{recurrence}->{dtstart}->{year},
            month  => $xmlTree->{recurrence}->{dtstart}->{month},
            day    => $xmlTree->{recurrence}->{dtstart}->{day},
            hour   => $xmlTree->{recurrence}->{dtstart}->{hour},
            minute => $xmlTree->{recurrence}->{dtstart}->{minute},
            second => $xmlTree->{recurrence}->{dtstart}->{second}
            )
            : DateTime::Infinite::Past->new;

        my $dtend
            = defined $xmlTree->{recurrence}->{dtend}
            ? DateTime->new(
            year   => $xmlTree->{recurrence}->{dtend}->{year},
            month  => $xmlTree->{recurrence}->{dtend}->{month},
            day    => $xmlTree->{recurrence}->{dtend}->{day},
            hour   => $xmlTree->{recurrence}->{dtend}->{hour},
            minute => $xmlTree->{recurrence}->{dtend}->{minute},
            second => $xmlTree->{recurrence}->{dtend}->{second}
            )
            : DateTime::Infinite::Future->new;

        warn Dumper( $xmlTree->{recurrence}->{byday} );

        %recurrence = (
            freq     => $xmlTree->{recurrence}->{freq},
            interval => (
                ( defined $xmlTree->{recurrence}->{interval} )
                ? $xmlTree->{recurrence}->{interval}
                : 1
            ),
            dtstart  => $dtstart,
            dtend    => $dtend,
            byminute => defined $xmlTree->{recurrence}->{byminute}
            ? $xmlTree->{recurrence}->{byminute}->{by}
            : (),
            byhour => defined $xmlTree->{recurrence}->{byhour}
            ? $xmlTree->{recurrence}->{byhour}->{by}
            : (),
            byday => defined $xmlTree->{recurrence}->{byday}
            ? $xmlTree->{recurrence}->{byday}->{by}
            : (),
            bymonthday => defined $xmlTree->{recurrence}->{bymonthday}
            ? $xmlTree->{recurrence}->{bymonthday}->{by}
            : (),
            bymonth => defined $xmlTree->{recurrence}->{bymonth}
            ? $xmlTree->{recurrence}->{bymonth}->{by}
            : (),
        );

        my $set   = DateTime::Event::ICal->recur(%recurrence);
        my $spans = DateTime::SpanSet->from_set_and_duration(
            set     => $set,
            minutes => $xmlTree->{duration},
        );
        $obj = $class->SUPER::from_spans( spans => $spans, );
    }

    $obj->{ __PACKAGE__ . "::id" }
        = ( defined $xmlTree->{id} ) ? $xmlTree->{id}
        : ( defined $id ) ? $id
        :                   Smeagol::DataStore->getNextID(__PACKAGE__);

    $obj->{ __PACKAGE__ . "::description" } = $xmlTree->{description};
    $obj->{ __PACKAGE__ . "::info" }
        = defined( $xmlTree->{info} ) ? $xmlTree->{info} : '';
    $obj->{ __PACKAGE__ . "::recurrence" }
        = defined( $xmlTree->{recurrence} ) ? \%recurrence : undef;
    $obj->{ __PACKAGE__ . "::duration" }
        = defined( $xmlTree->{duration} ) ? $xmlTree->{duration} : undef;

    bless $obj, $class;
    return $obj;
}

=item $booking->id

=item $booking->id( $str )

Get or set the Booking ID. The ID is used internally by the persistence 
subsystem and should not be modified by the user. 

=cut

sub id {
    my $self = shift;

    my $field = __PACKAGE__ . "::id";
    if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

=item $booking->description

=item $booking->description( $str )

Get or set the Booking description.

=cut

sub description {
    my $self = shift;

    my $field = __PACKAGE__ . "::description";
    if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

=item $booking->info

=item $booking->info( $str )

Get or set the Booking additional information.

=cut

sub info {
    my $self = shift;

    my $field = __PACKAGE__ . "::info";
    if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

# Aquest mètode és només de lectura.
# Si es permet modificar la recurrència, caldria tornar a generar l'SpanSet!!!
sub recurrence {
    my $self = shift;

    my $field = __PACKAGE__ . "::recurrence";

    #if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

# Aquest mètode és només de lectura.
# Si es permetés modificar la duració, caldria tornar a generar l'SpanSet!!!
sub duration {
    my $self = shift;

    my $field = __PACKAGE__ . "::duration";

    #if (@_) { $self->{$field} = shift; }

    return $self->{$field};
}

sub url {
    my $self = shift;

    return "/booking/" . $self->id;
}

=item $booking->isEqual( $anotherBooking )

Booking comparator. Both bookings must have equal description and info attributes, and
must represent the same DateTime::SpanSet.

=cut

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

=item $booking->isNotEqual( $anotherBooking )

Returns true if and only if !( $booking->isEqual( $anotherBooking) ) 

=cut

sub isNotEqual {
    return !shift->isEqual(@_);
}

=item $booking->toString

Returns a serialized representation of the Booking (in XML format). See Booking DTD for additional info.

=cut

sub toString {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $from = $self->span->start;
    my $to   = $self->span->end;
    my $xmlText
        = "<booking>" . "<id>"
        . $self->id . "</id>"
        . "<description>"
        . $self->description
        . "</description>";

    if ( !$self->recurrence ) {
        $xmlText
            .= "<from>" 
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
            . "</second>" . "</to>";
    }
    else {
        $xmlText .= "<recurrence>"
            . "<freq>"
            . $self->recurrence->{'freq'}
            . "</freq>";

        if (defined $self->recurrence->{'interval'}) {
            $xmlText .= "<interval>" . $self->recurrence->{'interval'} . "</interval>";
        }

        if ( $self->recurrence->{'dtstart'} ) {
            my $dt = $self->recurrence->{'dtstart'};
            $xmlText
                .= "<dtstart>" 
                . "<year>"
                . $dt->year
                . "</year>"
                . "<month>"
                . $dt->month
                . "</month>" 
                . "<day>"
                . $dt->day
                . "</day>"
                . "<hour>"
                . $dt->hour
                . "</hour>"
                . "<minute>"
                . $dt->minute
                . "</minute>"
                . "<second>"
                . $dt->second
                . "</second>"
                . "</dtstart>";
        }

        if ( defined $self->recurrence->{'dtend'} ) {
            my $dt = $self->recurrence->{'dtend'};
            $xmlText
                .= "<dtend>" 
                . "<year>"
                . $dt->year
                . "</year>"
                . "<month>"
                . $dt->month
                . "</month>" 
                . "<day>"
                . $dt->day
                . "</day>"
                . "<hour>"
                . $dt->hour
                . "</hour>"
                . "<minute>"
                . $dt->minute
                . "</minute>"
                . "<second>"
                . $dt->second
                . "</second>"
                . "</dtend>";
        }

        if ( defined $self->recurrence->{'byminute'} ) {
            $xmlText .= "<byminute>";
            foreach ( @{$self->recurrence->{'byminute'}} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</byminute>";
        }

        if ( defined $self->recurrence->{'byhour'} ) {
            $xmlText .= "<byhour>";
            foreach ( @{$self->recurrence->{'byhour'}} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</byhour>";
        }

        if ( defined $self->recurrence->{'byday'} ) {
            $xmlText .= "<byday>";
            foreach ( @{$self->recurrence->{'byday'}} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</byday>";
        }

        if ( defined $self->recurrence->{'bymonthday'} ) {
            $xmlText .= "<bymonthday>";
            foreach ( @{$self->recurrence->{'bymonthday'}} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</bymonthday>";
        }

        if ( defined $self->recurrence->{'bymonth'} ) {
            $xmlText .= "<bymonth>";
            foreach ( @{$self->recurrence->{'bymonth'}} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</bymonth>";
        }

        $xmlText .= "</recurrence>";
        $xmlText .= "<duration>" . $self->duration . "</duration>";
    }

    $xmlText .= "<info>" . $self->info . "</info>" . "</booking>";

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
sub toXML {
    return shift->toString(@_);
}

sub ical {
    my $self = shift;

    my $class = __PACKAGE__ . "::ICal";

    eval "require $class";
    return bless $self, $class;
}

1;
