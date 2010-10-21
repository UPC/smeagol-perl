package V2::Client::Tag;

use strict;
use warnings;

use Moose;

#use Data::Dumper;

use HTTP::Request::Common;
use HTTP::Response;
use HTTP::Status qw(:constants :is status_message);
use JSON::Any;
use URI;
use Data::Dumper;

extends 'V2::Client';

my $REST_SEGMENT = 'tag';    # http://.../tag

has 'id' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has 'description' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

override '_fullPath' => sub {
    my $self = shift;
    my $uri  = URI->new( $self->url );
    $uri->path_segments($REST_SEGMENT);
    return $uri->as_string;
};

#
# Retrieve all existing tags
# Arguments: none
#
sub list {
    my $self = shift;

    my $res = $self->ua->get( $self->_fullPath() );

    return unless $res->code == HTTP_OK;

    my @tagList;

    my $objectList = JSON::Any->from_json( $res->content, { utf8 => 1 } );

    foreach (@$objectList) {
        my $tag = V2::Client::Tag->new( url => $self->url );
        $tag->{id}          = $_->{'id'};
        $tag->{description} = $_->{'description'};
        push @tagList, $tag;
    }
    return @tagList;
}

#
# Create a new tag
# Arguments:
#
#   id (mandatory)
#   description (mandatory)
#
sub create {
    my $self = shift;
    my %args = @_;
    my ( $id, $description ) = ( $args{id}, $args{description} );
    return unless ( defined $id && defined $description );

    my $res = $self->ua->post( $self->_fullPath,
        [ id => $id, description => $description ] );

    return unless $res->code == HTTP_CREATED;

    # after creation, the server returns the location of the new
    # tag as an HTTP header, but we must return a Client::Tag instance
    return $self->get( $res->header('Location') );
}

#
# Retrieve tag from server
# Arguments:
#   id (mandatory)
#
sub get {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $res = $self->ua->get( $self->_fullPath . '/' . $id );

    if ( $res->code == HTTP_OK ) {
        my $tag = JSON::Any->from_json( $res->content, { utf8 => 1 } );
        $self->{id} = $tag->{'id'};
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
        POST => $self->url . '/resource/' . $id . $REST_SEGMENT );
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

__END__

=head1 NAME

Smeagol::Client::Tag - A Smeagol client for 'tags' management

=head1 SYNOPSIS

 my $ct = Smeagol::Client::Tag->new( $url => 'http://my_smeagol_server/' );
 
 my $t1 = $ct->create( id => 'classroom', 'A classroom');
 print $t1->id;
 print $t1->description;
 
 my $t2 = $ct->update( id => 'classroom', 'A NEW classroom');
 print $t2->description;

 my $t3 = $ct->get( id => 'anotherTag' );

 $ct->del( id => 'classroom' );

 my @tags = $ct->list(); 

=head1 DESCRIPTION

This module implements the Smeagol::Client::Tag class. An instance of this class
acts as a Smeagol client and is also a representation of the 'tag' entity on the
client side (as the internal implementation of 'tags' on the server remains
hidden to the client).

This class provides several methods which allow for CRUD management of 'tag'
objects on the server.

Tag objects have two attributes, 'id' and 'description'. The id is defined on
tag creation, and is immutable. The description may be modified after creation,
and is often used to complement the semantics to the 'id'.

=head1 CONSTRUCTORS

=over 4

=item $ct = Smeagol::Client::Tag->new( url => 'http://server:port');

Return a new Smeagol::Client::Tag instance. A Smeagol server URL is required.

=back

=head1 METHODS

=over 4

=item $tag = $client->create( id => 'myTag', description => 'myDesc' );

Creates a new tag on the server, with specified 'id' and 'description'. The
returned object is also a Smeagol::Client::Tag instance.

=item $tag->description

=item $tag->description( 'newDesc' );

Getter and setter for tag description. Note that modifying the description using
the setter will not modify the object on the server (for this purpose, 
use the update() method).

=item $tag->id

=item $tag->id( 'newId' )

Getter and setter for tag id. Note that modifying the id using the setter will
not modify the object on the server (for this purpose, use the update() method).

=item $tag = $ct->get( id => 'myTag' )

Retrieve a single tag from server. The 'id' argument is required. If no tag was
found with the provided id, the result will be C<undef>.

=item @tags = $ct->list()

Retrieve a (possibly empty) list containing all tags in the server.

=item $tag = $ct->update( id => 'newId', description => 'newDesc' )

Update tag attributes on server.

=back
=cut
