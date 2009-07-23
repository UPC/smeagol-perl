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

use overload
    q{""} => \&toString,
    q{==} => \&isEqual,
    q{eq} => \&isEqual,
    q{!=} => \&isNotEqual,
    q{ne} => \&isNotEqual;

my @VALID_FREQ
    = ( 'minutely', 'hourly', 'daily', 'weekly', 'monthly', 'yearly' );
my @VALID_BYDAY = ( 'mo', 'tu', 'we', 'th', 'fr', 'sa', 'su' );

# %recurrence = (
#            freq     => string (required: 'weekly', 'monthly', see @VALID_FREQ)
#            interval => positive integer (optional, default 1)
#            duration => positive integer (required)
#            dtstart  => DateTime (optional, default DateTime::Infinite::Past)
#            dtend    => DateTime (optional, default DateTime::Infinite::Future)
#            byminute => array of positive integers between 0 and 59 (optional, default () )
#            byhour   => array of positive integers between 0 and 23 (optional, default () )
#            byday    => array of strings, see @VALID_BYDAY, possibly prefixed by an integer,
#                        i.e. "2th", "-1mo", etc. (optional, default ())
#            bymonthday => list integers between -31 and 1, or between 1 and 31 (optional, default () )
#            )
sub new {
    my $class = shift;
    my ( $description, $from, $to, $info, %recurrence ) = @_;

    return if ( !defined($description) );

    # must specify (from AND to) XOR (recurrence)
    return
        unless ( ( defined($from) && defined($to) && !(%recurrence) )
        || ( !defined($from) && !defined($to) && (%recurrence) ) );

    my $obj;

    if (%recurrence) {
        my $set = DateTime::Event::ICal->recur(%recurrence);

        $obj = $class->SUPER::from_set_and_duration(
            set     => $set,
            minutes => defined( $recurrence{'duration'} )
            ? $recurrence{'duration'}
            : ( 60 * 24 ),
        );

    }
    else {
        my $span = DateTime::Span->from_datetimes(
            start => $from,
            end   => $to,
        );

        $obj = $class->SUPER::from_spans( spans => [$span], );
    }

    $obj->{ __PACKAGE__ . "::description" } = $description;
    $obj->{ __PACKAGE__ . "::id" }
        = Smeagol::DataStore->getNextID(__PACKAGE__);
    $obj->{ __PACKAGE__ . "::info" } = defined($info) ? $info : '';
    $obj->{ __PACKAGE__ . "::recurrence" } = \%recurrence if (%recurrence);

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

sub recurrence {
    my $self = shift;

    my $field = __PACKAGE__ . "::recurrence";
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
        $xmlText
            = "<booking>" . "<id>"
            . $self->id . "</id>"
            . "<description>"
            . $self->description
            . "</description>"
            . "<recurrence>"
            . "<freq>"
            . $self->recurrence->{'freq'}
            . "</freq>"
            . "<interval>"
            . $self->recurrence->{'interval'}
            . "</interval>"
            . "<duration>"
            . $self->recurrence->{'duration'}
            . "</duration>";

        if ( $self->recurrence->{'dtstart'} ) {
            my $dt = $self->recurrence->{'dtstart'};
            $xmlText
                .= "<dtstart>" 
                . "<year>"
                . $dt->{'year'}
                . "</year>"
                . "<month>"
                . $dt->{'month'}
                . "</month>" . "<day>"
                . $dt->{'day'}
                . "</day>"
                . "<hour>"
                . $dt->{'hour'}
                . "</hour>"
                . "<minute>"
                . $dt->{'minute'}
                . "</minute>"
                . "<second>"
                . $dt->{'second'}
                . "</second>"
                . "</dtstart>";
        }

        if ( defined $self->recurrence->{'dtend'} ) {
            my $dt = $self->recurrence->{'dtend'};
            $xmlText
                .= "<dtend>" 
                . "<year>"
                . $dt->{'year'}
                . "</year>"
                . "<month>"
                . $dt->{'month'}
                . "</month>" . "<day>"
                . $dt->{'day'}
                . "</day>"
                . "<hour>"
                . $dt->{'hour'}
                . "</hour>"
                . "<minute>"
                . $dt->{'minute'}
                . "</minute>"
                . "<second>"
                . $dt->{'second'}
                . "</second>"
                . "</dtend>";
        }

        if ( defined $self->recurrence->{'byminute'} ) {
            $xmlText .= "<byminute>";
            foreach ( $self->recurrence->{'byminute'} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</byminute>";
        }

        if ( defined $self->recurrence->{'byhour'} ) {
            $xmlText .= "<byhour>";
            foreach ( $self->recurrence->{'byhour'} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</byhour>";
        }

        if ( defined $self->recurrence->{'byday'} ) {
            $xmlText .= "<byday>";
            foreach ( $self->recurrence->{'byday'} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</byday>";
        }

        if ( defined $self->recurrence->{'bymonthday'} ) {
            $xmlText .= "<bymonthday>";
            foreach ( $self->recurrence->{'bymonthday'} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</bymonthday>";
        }

        if ( defined $self->recurrence->{'bymonth'} ) {
            $xmlText .= "<bymonth>";
            foreach ( $self->recurrence->{'bymonth'} ) {
                $xmlText .= "<by>" . $_ . "</by>";
            }
            $xmlText .= "</bymonth>";
        }

        $xmlText .= "</recurrence>";
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
    my $xmlTree = XMLin( $xml, SuppressEmpty => '' );

    my $span = DateTime::Span->from_datetimes(
        start => DateTime->new(
            year   => $xmlTree->{from}->{year},
            month  => $xmlTree->{from}->{month},
            day    => $xmlTree->{from}->{day},
            hour   => $xmlTree->{from}->{hour},
            minute => $xmlTree->{from}->{minute},
            second => $xmlTree->{from}->{second}
        ),
        end => DateTime->new(
            year   => $xmlTree->{to}->{year},
            month  => $xmlTree->{to}->{month},
            day    => $xmlTree->{to}->{day},
            hour   => $xmlTree->{to}->{hour},
            minute => $xmlTree->{to}->{minute},
            second => $xmlTree->{to}->{second}
        )
    );

    my $obj = $class->SUPER::from_spans( spans => [$span], );

    $obj->{ __PACKAGE__ . "::id" }
        = ( defined $xmlTree->{id} ) ? $xmlTree->{id}
        : ( defined $id ) ? $id
        :                   Smeagol::DataStore->getNextID(__PACKAGE__);

    $obj->{ __PACKAGE__ . "::description" } = $xmlTree->{description};
    $obj->{ __PACKAGE__ . "::info" }
        = defined( $xmlTree->{info} ) ? $xmlTree->{info} : '';

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
