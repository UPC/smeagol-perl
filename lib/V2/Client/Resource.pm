package Smeagol::Client::Resource;

use strict;
use warnings;
use Moose;
use Data::Dumper;
#use XML::LibXML;
#use XML::Simple;
#use Smeagol::XML;
use HTTP::Request::Common;
use JSON;
use Smeagol::Client::Tag;


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

has 'tags' => ( is => 'rw', required => 0, );

#Cal afegir els tags i els events



sub list {
    my $self = shift;

    my $res = $self->ua->get( $self->url."/resource" );
    return unless $res->status_line =~ /200/;

    my @idResources;

	my $perl_scalar = from_json($res->content , { utf8  => 1 } );
    foreach(@$perl_scalar){
	  if(defined $$perl_scalar[0]){
		my $scr = Smeagol::Client::Resource->new(url => $self->url);
		$scr->{id}  	= '/resource/'.$_->{'id'};
        $scr->{info}	= $_->{'info'};
        $scr->{desc} 	= $_->{'description'};
        $scr->{tags} 	= $_->{'tags'};
        push @idResources, $scr;
	  }
	}
    return @idResources;
}

sub create {
    my $self = shift;
    my %args = @_;
    my ( $description, $info, $tags ) = ($args{desc}, $args{info}, $args{tags});
    return unless defined $description;

	my $res = $self->ua->request(POST $self->url.'/resource', [ description => $description, info =>  $info, tags => $tags]);
	my $perl_scalar = from_json($res->content , { utf8  => 1 } );
	$self->{id}  	= '/resource/'.$perl_scalar->[0]->{'id'};
   	$self->{info}	= $perl_scalar->[0]->{'info'};
   	$self->{desc} 	= $perl_scalar->[0]->{'description'};
	foreach(@{$$perl_scalar[0]->{'tags'}}){
   		push @{$self->{tags}}, Smeagol::Client::Tag->new(url => $self->url, id => '/tag/'.$_->{id});
	}
    return $self;
}

sub get {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $res = $self->ua->get( $self->url . $id );

    if ( $res->status_line =~ /200/ ) {
		my $perl_scalar = from_json($res->content , { utf8  => 1 } );
	    $self->{id} = '/resource/'.$perl_scalar->{'id'};
	    $self->{desc} = $perl_scalar->{'description'};
	    $self->{info} = $perl_scalar->{'info'};
		foreach(@{$perl_scalar->{'tags'}}){
   			push @{$self->{tags}}, Smeagol::Client::Tag->new(url => $self->url, id => '/tag/'.$_->{id});
		}
        return $self;
    }
    return;
}


sub update {
    my $self = shift;
    my %args = @_;
    my ( $id) = ($args{id});

    return unless defined $id ;

	my $res = $self->get($id);

	my ( $desc, $info, $tags );
	$desc = (defined $args{desc})? $args{desc} : $res->desc;
	$info = (defined $args{info})? $args{info} : $res->info;
	$tags = (defined $args{tags})? $args{tags} : $res->tags;

#FIXME: Si no se modifican los tags, $res->tags contiene un array de objetos de tipo Smeagol::Client::Tag

	my $req = HTTP::Request->new( PUT  $self->url.$id); 

#    my $res = $self->ua->request( PUT  $self->url.$id, [ description => $desc, info =>  $info, tags => $tags]);
    my $res = $self->ua->request( $req, [ description => $desc, info =>  $info, tags => $tags]);

    my $result = $self->get($id);
    return $result;

}


sub delete {
    my $self = shift;
    my ($id) = @_;

    return unless defined $id;

    my $req
        = HTTP::Request->new( DELETE => $self->url . $id );
    $req->content_type('text/xml');

    my $res = $self->ua->request($req);
    return unless $res->status_line =~ /200/;

	my $perl_scalar = from_json($res->content , { utf8  => 1 } );
    $self->{id} = '/resource/'.$perl_scalar->{'id'};

    return $self;
}


1;
