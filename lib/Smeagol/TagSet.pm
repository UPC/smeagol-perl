package Smeagol::TagSet;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
use XML::LibXML;
use Smeagol::Tag;
use Data::Dumper;
use Smeagol::XML;
use Carp;

use overload q{""} => \&__str__;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
    return $obj;
}

sub append {
    my $self = shift;
    my ($slot) = @_;

    ( defined $slot ) or die "SetTag->append requires one parameter";

    $self->insert($slot);
}

sub __str__ {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $xmlText = "<tags>";
    for my $slot ( $self->elements ) {
        $xmlText .= $slot->toXML($url);
    }
    $xmlText .= "</tags>";

    return $xmlText
        unless defined $url;

    my $xmlDoc = eval { Smeagol::XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "tags", $url . "/tags" );
    if ($isRootNode) {
        $xmlDoc->addPreamble("tags");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("tags")->[0];
        return $node->toString;
    }
}

sub to_xml {
    return shift->__str__(@_);
}

sub from_xml {
    my $class = shift;
    my ($xml) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//TagSet DTD v0.01",
        "share/dtd/tagSet.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
    }

    # at this point, we are certain that $xml was a valid XML
    # representation of a TagSet object; that is,
    # $dom variable contains a DOM (Document Object Model)
    # representation of the $xml string

    my $tgS = $class->SUPER::new();
    bless $tgS, $class;

    # traverse all '<tag>' elements found in DOM structure.
    # note: all intersecting bookings in the agenda will be ignored,
    # because we use the "append" method to store tags in the
    # $tgs object, so we do not need to worry about eventual
    # intersections present in the $xml
    for my $tag_dom_node ( $dom->getElementsByTagName('tag') ) {
        my $tg = Smeagol::Tag->from_xml( $tag_dom_node->toString(0) );
        $tgS->append($tg);
    }

    return $tgS;
}

1;
