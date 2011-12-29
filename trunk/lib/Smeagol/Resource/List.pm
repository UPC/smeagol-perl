package Smeagol::Resource::List;

use strict;
use warnings;

use Smeagol::DataStore;
use Smeagol::Resource;
use XML::LibXML;
use Smeagol::XML;
use Carp;

use overload q{""} => \&toString;

sub new {
    my $class = shift;

    my $obj = [];

    foreach my $id ( Smeagol::DataStore->getIDList ) {
        my $r = Smeagol::Resource->load($id);
        push @$obj, $r if defined $r;
    }

    bless $obj, $class;
    return $obj;
}

sub toSmeagolXML {
    my $self        = shift;
    my $xlinkPrefix = shift;

    my $result = eval { Smeagol::XML->new('<resources/>') };
    croak $@ if $@;

    $result->addPreamble('resources');
    my $dom           = $result->doc;
    my $resourcesNode = $dom->documentElement;

    for my $slot (@$self) {
        my $rNode = $slot->toSmeagolXML("")->documentElement;
        $dom->adoptNode($rNode);
        $resourcesNode->appendChild($rNode);
    }

    if ( defined $xlinkPrefix ) {
        $result->addXLink( "resources", $xlinkPrefix );
    }

    return $result;
}

sub toString {
    my $self = shift;
    my $url  = shift;

    return $self->toSmeagolXML($url)->toString;
}

sub toXML {
    return shift->toString(@_);
}

sub newFromXML {
    my $class = shift;
    my ($xml) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Resources DTD v0.03",
        "dtd/resoure-list.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
    }

    my $obj = [];
    bless $obj, $class;

    for my $domResource ( $dom->getElementsByTagName('resource') ) {
        push @$obj, Resouce->newFromXML( $domResource->toString(0) );
    }

    return $obj;
}

1;
