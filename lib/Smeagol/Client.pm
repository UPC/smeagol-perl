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
    for my $resNode ( $dom->getElementsByTagName('resource') ) {
        my $idRes = $resNode->getAttribute('xlink:href');
        push @idResources, $idRes;
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
    my $req = HTTP::Request->new( POST => $self->{url} . "/resource" );
    $req->content_type('text/xml');
    $req->content($respXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /201/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    return $dom->getElementsByTagName('resource')->get_node(1)
        ->getAttribute('xlink:href');
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
    return $dom->getElementsByTagName('booking')->get_node(1)
        ->getAttribute('xlink:href');
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

    return $dom->getElementsByTagName('tag')->get_node(1)
        ->getAttribute('xlink:href');
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
        my $resource = XMLin( $res->content );
        if ( defined $resource->{idAgenda} ) {
            $resource->{agenda}
                = $dom->getElementsByTagName('agenda')->get_node(1)
                ->getAttribute('xlink:href');
        }
        return $resource;
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
    return XMLin( $res->content );
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
    my @bookings;
    for my $node ( $dom->getElementsByTagName('booking') ) {
        push @bookings, $node->getAttribute('xlink:href');
    }
    return @bookings;
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
    my @tags;
    for my $node ( $dom->getElementsByTagName('tag') ) {
        push @tags, $node->getAttribute('xlink:href');
    }
    return @tags;
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
    my $req = HTTP::Request->new(
        POST => $self->{url} . '/resource/' . $id );

    $req->content_type('text/xml');
    $req->content($respXML);

    my $res = $self->{ua}->request($req);
    return unless $res->status_line =~ /200/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;
    return $dom->getElementsByTagName('resource')->get_node(1)
        ->getAttribute('xlink:href');
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
    return $dom->getElementsByTagName('booking')->get_node(1)
        ->getAttribute('xlink:href');
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

    return $id;
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

    return $bid;
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

    return $tid;
}

1;
