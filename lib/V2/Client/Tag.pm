package V2::Client::Tag;

use strict;
use warnings;

use Moose;
use Data::Dumper;

use HTTP::Request::Common;
use JSON;

extends 'V2::Client';

has 'id' => (
    is       => 'rw',
    required => 1,
    default  => sub {
        my $self = shift;
        my %args = @_;
        return $args{name};
    }
);

sub list {
    my $self = shift;

    my $res = $self->ua->get( $self->url . "/tag" );
    return unless $res->status_line =~ /200/;

    my @idTags;

    my $perl_scalar = from_json( $res->content, { utf8 => 1 } );
    foreach (@$perl_scalar) {
        if ( defined $$perl_scalar[0] ) {
            my $scr = V2::Client::Tag->new( url => $self->url );
            $scr->{id}   = '/tag/' . $_->{'id'};
            $scr->{name} = $_->{'name'};
            push @idTags, $scr;
        }
    }
    return @idTags;
}

sub create {
    my $self   = shift;
    my %args   = @_;
    my ($name) = ( $args{name} );
    return unless defined $name;

    #    my $req = HTTP::Request->new( POST => $self->url . "/tag" );
    #    $req->content_type('text/plain');
    #    $()req->content($respXML);

    my $res
        = $self->ua->request( POST $self->url . '/tag', [ name => $name ] );

    #    return unless $res->status_line =~ /201/;

    my $perl_scalar = from_json( $res->content, { utf8 => 1 } );
    if ( ref($perl_scalar) eq 'ARRAY' ) {
        $self->{id}   = '/tag/' . $$perl_scalar[0]->{'id'};
        $self->{name} = $$perl_scalar[0]->{'name'};
    }
    return $self;
}

sub get {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $res = $self->ua->get( $self->url . $id );

    if ( $res->status_line =~ /200/ ) {
        my $perl_scalar = from_json( $res->content, { utf8 => 1 } );
        $self->{id}   = '/tag/' . $perl_scalar->{'id'};
        $self->{name} = $perl_scalar->{'name'};
        return $self;
    }
    return;
}

sub update {
    my $self = shift;
    my %args = @_;
    my ( $id, $name ) = ( $args{id}, $args{name}, $args{name} );

    # $info is not mandatory
    return unless defined $id && defined $name;

 #    my $req = HTTP::Request->new( POST => $self->url . '/resource/' . $id );
 #    $req->content_type('text/xml');
 #    $req->content($respXML);

    my $res = $self->ua->request( POST $self->url . $id, [ name => $name ] );

    #    return unless $res->status_line =~ /200/;

    my $perl_scalar = from_json( $res->content, { utf8 => 1 } );
    $self->{id}   = '/tag/' . $$perl_scalar[0]->{'id'};
    $self->{name} = $$perl_scalar[0]->{'name'};
    return $self;

}

sub delete {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $req = HTTP::Request->new( DELETE => $self->url . $id );
    $req->content_type('text/xml');

    my $res = $self->ua->request($req);
    return unless $res->status_line =~ /200/;

    my $perl_scalar = from_json( $res->content, { utf8 => 1 } );
    $self->{message} = $perl_scalar->{'Message'};

    return $self;
}

sub tag {
    my $self = shift;
    my ( $id, $description ) = @_;

    return
        unless defined $id
            && defined $description;

    my $req = HTTP::Request->new(
        POST => $self->url . '/resource/' . $id . '/tag' );
    $req->content_type('text/xml');
    my $tagXML = "<tag>$description</tag>";
    $req->content($tagXML);

    my $res = $self->ua->request($req);
    return unless $res->status_line =~ /201/;

    my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
    croak $@ if $@;

    my $result = XMLin( $res->content );
    $result->{url} = $self->url . $result->{'xlink:href'};
    $result->{idR} = _idResource( $result->{'xlink:href'} );
    return $result;
}

sub untag {
    my $self = shift;
    my ( $rid, $tid ) = @_;

    return unless ( defined $rid && defined $tid );

    my $req = HTTP::Request->new(
        DELETE => $self->url . '/resource/' . $rid . '/tag/' . $tid );
    $req->content_type('text/xml');

    my $res = $self->ua->request($req);
    return unless $res->status_line =~ /200/;

    return { content => $tid };
}

1;
