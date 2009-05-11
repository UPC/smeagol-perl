package Smeagol::Resource::List;

use strict;
use warnings;

use Smeagol::DataStore;
use Smeagol::Resource;
use XML::LibXML;
use Smeagol::XML;
use Carp;

use overload q{""} => \&__str__;

sub new {
    my $class = shift;

    my $obj = [];

    foreach my $id ( Smeagol::DataStore->list_id ) {
        my $r = Smeagol::Resource->load($id);
        push @$obj, $r if defined $r;
    }

    bless $obj, $class;
    return $obj;
}

sub __str__ {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $xmlText = "<resources>";
    for my $slot (@$self) {
        $xmlText .= $slot->to_xml("");
    }
    $xmlText .= "</resources>";

    return $xmlText
        unless defined $url;

    my $xmlDoc = eval { Smeagol::XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "resources", $url );
    if ($isRootNode) {
        $xmlDoc->addPreamble("resources");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("resources")->[0];
        return $node->toString;
    }
}

# DEPRECATED
sub to_xml {
    return shift->__str__(@_);
}

sub from_xml {
    my $class = shift;
    my ($xml) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Resources DTD v0.03",
        "share/dtd/resoure-list.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
    }

    my $obj = [];
    bless $obj, $class;

    for my $domResource ( $dom->getElementsByTagName('resource') ) {
        push @$obj, Resouce->from_xml( $domResource->toString(0) );
    }

    return $obj;
}

1;
