package Smeagol::Client::Agenda;

use strict;
use warnings;
use Moose;
use Data::Dumper;

extends 'Smeagol::Client';

has 'desc' => (
		is => 'rw',
		required => 1,
		default => sub {
		        	my $self = shift;
				my %args = @_;
        			return $args{desc};
    		}
	     );
has 'info' => (
		is => 'rw',
		required => 0,
		default => sub {
		        	my $self = shift;
				my %args = @_;
        			return $args{info} if (defined $args{info});
    		});
has 'id' => ( is => 'rw', required => 0);
has 'agenda' => (is => 'rw', isa => 'Smeagol::Client::Agenda', required => 0);
#Cal afegir els tags i els events



sub list {
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

sub create {
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

sub get {
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


sub update {
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

    my $result = $self->getResource($id);
    return $result;

}


sub delete {
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

sub tag {
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

sub untag {
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

1;
