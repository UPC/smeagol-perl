package Smeagol::Client;

use strict;
use warnings;

use DateTime;
use LWP::UserAgent;
use Carp;
use Data::Dumper;
use XML::LibXML;
use XML::Simple;

my %COMMAND_VALID = map { $_ => 1 } qw( POST GET PUT DELETE );

sub new {
    my $class = shift;
    my ($url) = @_;

    return unless defined $url;

    my $ua = LWP::UserAgent->new();
    $ua->agent("SmeagolClient/0.1 ");

    my $obj = {
        url => $url,
        ua  => $ua,
    };

    bless $obj, $class;

    # Should be 0 or more if server is working
    my $numResources = $obj->listResources();
    return unless defined $numResources;

    return $obj;
}

sub listResources {
    my $self = shift;

    my $res = $self->{ua}->get( $self->{url} . "/resources" );
    return unless $res->status_line =~ /200/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    my @idResources;

    my $resources = XMLin( $res->content );
    if ( ref( $resources->{resource} ) eq 'HASH' ) {
        my $node = $resources->{resource};
        $node->{id}     = _idResource( $node->{'xlink:href'} );
        $node->{url}    = $self->{url} . $node->{'xlink:href'};
        $node->{agenda} = $self->{url} . $node->{'xlink:href'} . "/bookings"
            if ( defined $node->{idAgenda} );
        push @idResources, $node;
    }
    elsif ( ref( $resources->{resource} ) eq 'ARRAY' ) {
        foreach my $node ( @{ $resources->{resource} } ) {
            $node->{id}  = _idResource( $node->{'xlink:href'} );
            $node->{url} = $self->{url} . $node->{'xlink:href'};
            $node->{agenda}
                = $self->{url} . $node->{'xlink:href'} . "/bookings"
                if ( defined $node->{idAgenda} );
            push @idResources, $node;
        }
    }
    return @idResources;
}

sub createResource {
    my $self = shift;
    my ( $description, $info ) = @_;

    # $info is not mandatory
    return unless defined $description;

    my $respXML = "<resource>
        <description>$description</description>
        <info>" . ( ( defined $info ) ? $info : "" ) . "</info>
        </resource>";

    # Two calls to the server are required:
    #    * one call to create the booking and get its location
    #    * another call to retrieve the booking from the server

    # request to create booking
    my $req = HTTP::Request->new( POST => $self->{url} . "/resource" );
    $req->content_type('text/xml');
    $req->content($respXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /201/;

    # request to retrieve booking
    my $location = $res->header('Location');
    $res = $self->{ua}->get( $self->{url} . $location );
    return unless $res->status_line =~ /200/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;

    my $result = XMLin( $res->content );
    $result->{id}  = _idResource( $result->{'xlink:href'} );
    $result->{url} = $self->{url} . $result->{'xlink:href'};

    return $result;

}

sub createBooking {
    my $self = shift;
    my ( $id, $description, $from, $to, $info ) = @_;

    return
        unless defined $id
            && defined $description
            && ref($from) eq 'HASH'
            && ref($to)   eq 'HASH';

    my $req = HTTP::Request->new(
        POST => $self->{url} . '/resource/' . $id . '/booking' );
    $req->content_type('text/xml');
    my $bookingXML = "<booking>
        <description>$description</description>
        <from>
            <year>" . $from->{year} . "</year>
            <month>" . $from->{month} . "</month>
            <day>" . $from->{day} . "</day>
            <hour>" . $from->{hour} . "</hour>
            <minute>" . $from->{minute} . "</minute>
            <second>" . $from->{second} . "</second>
        </from>
        <to>
            <year>" . $to->{year} . "</year>
            <month>" . $to->{month} . "</month>
            <day>" . $to->{day} . "</day>
            <hour>" . $to->{hour} . "</hour>
            <minute>" . $to->{minute} . "</minute>
            <second>" . $to->{second} . "</second>
        </to>
        <info>" . ( ( defined $info ) ? $info : "" ) . "</info>
        </booking>";
    $req->content($bookingXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /201/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    my $result = XMLin( $res->content );
    $result->{idR} = _idResource( $result->{'xlink:href'} );
    $result->{url} = $self->{url} . $result->{'xlink:href'};
    return $result;
}

sub createTag {
    my $self = shift;
    my ( $id, $description ) = @_;

    return
        unless defined $id
            && defined $description;

    my $req = HTTP::Request->new(
        POST => $self->{url} . '/resource/' . $id . '/tag' );
    $req->content_type('text/xml');
    my $tagXML = "<tag>$description</tag>";
    $req->content($tagXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /201/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;

    my $result = XMLin( $res->content );
    $result->{url} = $self->{url} . $result->{'xlink:href'};
    $result->{idR} = _idResource( $result->{'xlink:href'} );
    return $result;
}

sub getResource {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $res = $self->{ua}->get( $self->{url} . '/resource/' . $id );

    #
    # FIXME: Cal controlar el cas que si/no hi hagi agenda
    #
    if ( $res->status_line =~ /200/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        croak $@ if $@;
        my $result = XMLin( $res->content );
        $result->{agenda}
            = $self->{url} . $result->{'xlink:href'} . "/bookings"
            if ( defined $result->{agenda} );
        $result->{id}  = _idResource( $result->{'xlink:href'} );
        $result->{url} = $self->{url} . $result->{'xlink:href'};
        return $result;
    }
    return;
}

sub getBooking {
    my $self = shift;
    my ( $rid, $bid, $viewAs ) = @_;

    return unless ( defined $bid && defined $rid );

    my $url = $self->{url} . '/resource/' . $rid . '/booking/' . $bid;
    $url .= "/" . $viewAs
        if defined $viewAs;

    my $res = $self->{ua}->get($url);
    return unless $res->status_line =~ /200/;

    return $res->content
        if defined $viewAs;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    my $result = XMLin( $res->content );
    $result->{idR} = _idResource( $result->{'xlink:href'} );
    $result->{url} = $self->{url} . $result->{'xlink:href'};
    return $result;
}

sub getBookingICal {
    return shift->getBooking( @_, "ical" );
}

sub listBookings {
    my $self = shift;
    my ( $id, $viewAs ) = @_;

    return unless defined $id;

    my $url = $self->{url} . '/resource/' . $id . '/bookings';
    $url .= "/" . $viewAs
        if defined $viewAs;

    my $res = $self->{ua}->get($url);
    return unless $res->status_line =~ /200/;

    return $res->content
        if defined $viewAs;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    my @idBookings;
    my $bookings = XMLin( $res->content, ForceArray => 1 );
    if ( defined( $bookings->{booking} )
        && !( defined $bookings->{booking}->[1] ) )
    {
        $bookings = XMLin( $res->content );
        my $result = $bookings->{booking};
        $result->{idR} = _idResource( $result->{'xlink:href'} );
        $result->{url} = $self->{url} . $result->{'xlink:href'};
        push @idBookings, $result;

    }
    elsif ( defined( $bookings->{booking} )
        && ( defined $bookings->{booking}->[1] ) )
    {
        $bookings = XMLin( $res->content );
        foreach my $id ( keys %{ $bookings->{booking} } ) {
            my $result = $bookings->{booking}->{$id};
            $result->{id}  = $id;
            $result->{idR} = _idResource( $result->{'xlink:href'} );
            $result->{url} = $self->{url} . $result->{'xlink:href'};
            push @idBookings, $result;
        }
    }
    return @idBookings;
}

sub listBookingsICal {
    return shift->listBookings( @_, "ical" );
}

sub listTags {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $url = $self->{url} . '/resource/' . $id . '/tags';

    my $res = $self->{ua}->get($url);
    return unless $res->status_line =~ /200/;
    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    my @idTags;
    my $tags = XMLin( $res->content );
    if ( ref( $tags->{tag} ) eq 'HASH' ) {
        push @idTags,
            {
            content => $tags->{tag}->{'content'},
            idR     => _idResource( $tags->{tag}->{'xlink:href'} ),
            url     => $self->{url} . $tags->{tag}->{'xlink:href'},
            };
    }
    elsif ( ref( $tags->{tag} ) eq 'ARRAY' ) {
        foreach my $node ( @{ $tags->{tag} } ) {
            push @idTags,
                {
                content => $node->{'content'},
                idR     => _idResource( $node->{'xlink:href'} ),
                url     => $self->{url} . $node->{'xlink:href'},
                };
        }
    }
    return @idTags;
}

sub updateResource {
    my $self = shift;
    my ( $id, $description, $info ) = @_;

    # $info is not mandatory
    return unless defined $id && defined $description;

    my $respXML = "<resource>
        <description>$description</description>
        <info>" . ( ( defined $info ) ? $info : "" ) . "</info>
        </resource>";
    my $req = HTTP::Request->new( POST => $self->{url} . '/resource/' . $id );

    $req->content_type('text/xml');
    $req->content($respXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /200/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;

    my $result = XMLin( $res->content );
    $result->{id}  = _idResource( $result->{'xlink:href'} );
    $result->{url} = $self->{url} . $result->{'xlink:href'};
    return $result;

}

sub updateBooking {
    my $self = shift;
    my ( $rid, $bid, $description, $from, $to, $info ) = @_;

    return
        unless defined $rid
            && defined $bid
            && defined $description
            && ref($from) eq 'HASH'
            && ref($to)   eq 'HASH';

    my $bookingXML = "<booking>
        <description>$description</description>
        <from>
            <year>" . $from->{year} . "</year>
            <month>" . $from->{month} . "</month>
            <day>" . $from->{day} . "</day>
            <hour>" . $from->{hour} . "</hour>
            <minute>" . $from->{minute} . "</minute>
            <second>" . $from->{second} . "</second>
        </from>
        <to>
            <year>" . $to->{year} . "</year>
            <month>" . $to->{month} . "</month>
            <day>" . $to->{day} . "</day>
            <hour>" . $to->{hour} . "</hour>
            <minute>" . $to->{minute} . "</minute>
            <second>" . $to->{second} . "</second>
        </to>
        <info>" . ( ( defined $info ) ? $info : "" ) . "</info>
        </booking>";

    my $req = HTTP::Request->new(
        POST => $self->{url} . '/resource/' . $rid . '/booking/' . $bid );
    $req->content_type('text/xml');
    $req->content($bookingXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /200/;
    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    my $result = XMLin( $res->content );
    $result->{url} = $self->{url} . $result->{'xlink:href'};
    $result->{idR} = _idResource( $result->{'xlink:href'} );
    return $result;
}

sub delResource {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $req
        = HTTP::Request->new( DELETE => $self->{url} . '/resource/' . $id );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /200/;

    return { id => $id };
}

sub delBooking {
    my $self = shift;
    my ( $rid, $bid ) = @_;

    return unless defined $rid && defined $bid;

    my $req = HTTP::Request->new(
        DELETE => $self->{url} . '/resource/' . $rid . '/booking/' . $bid );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /200/;

    return { id => $bid };
}

sub delTag {
    my $self = shift;
    my ( $rid, $tid ) = @_;

    return unless ( defined $rid && defined $tid );

    my $req = HTTP::Request->new(
        DELETE => $self->{url} . '/resource/' . $rid . '/tag/' . $tid );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /200/;

    return { content => $tid };
}

# Extracts the Resource ID from a given Resource REST URL
sub _idResource {
    my ($url) = shift;

    if ( $url =~ /\/resource\/(\w+)/ ) {
        return $1;
    }
    else {
        return;
    }
}

1;
