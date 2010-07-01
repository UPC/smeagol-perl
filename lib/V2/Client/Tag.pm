package V2::Client::Tag;

use strict;
use warnings;

use Moose;
use Data::Dumper;

use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Status qw(:constants :is status_message);
use JSON;

extends 'V2::Client';

has 'id' => (
    is       => 'rw',
    required => 1,
    default  => sub {
        my $self = shift;
        my %args = @_;
        return $args{id};
    }
);

sub list {
    my $self = shift;

    my $res = $self->ua->get( $self->url . "/tag" );

    return unless $res->code == HTTP_OK;

    my @tagList;

    my $j = JSON::Any->new;
    my $objectList = $j->from_json( $res->content, { utf8 => 1 } );

    foreach (@$objectList) {
        my $tag = V2::Client::Tag->new( url => $self->url );
        $tag->{id} = $_->{'id'};
        push @tagList, $tag;
    }
    return @tagList;
}

sub create {
    my $self = shift;
    my %args = @_;
    my ($id) = ( $args{id} );
    return unless defined $name;

    my $res
        = $self->ua->request( POST $self->url . '/tag', [ name => $name ] );

    die status_message(HTTP_BAD_REQUEST)
        unless $res->status_line == HTTP_CREATED;

    # the server returns the location of the new tag as an HTTP header
    return $self->get( $res->header('Location') );
}

sub get {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $res = $self->ua->get( $self->url . $id );

    if ( $res->status_line =~ /200/ ) {
        my $perl_scalar = from_json( $res->content, { utf8 => 1 } );
        $self->{id} = '/tag/' . $perl_scalar->{'id'};
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
