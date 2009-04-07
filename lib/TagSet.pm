package TagSet;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
use XML::LibXML;
use Tag;

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

    $self->insert($slot) ;
}

sub to_xml {
    my $self = shift;

    my $xml = "<tags>";

    for my $slot ( $self->elements ) {
        $xml .= $slot->toXML();
    }
    $xml .= "</tags>";

    return $xml;
}

sub from_xml {
    my $class = shift;
    my ($xml) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//TagSet DTD v0.01",
        "dtd/tagSet.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
    }

    # at this point, we are certain that $xml was a valid XML
    # representation of a TagSet object; that is,
    # $dom variable contains a DOM (Document Object Model)
    # representation of the $xml string

    my $tgs = $class->SUPER::new();
    bless $tgs, $class;

    # traverse all '<tag>' elements found in DOM structure.
    # note: all intersecting bookings in the agenda will be ignored,
    # because we use the "append" method to store tags in the
    # $tgs object, so we do not need to worry about eventual
    # intersections present in the $xml
    for my $tag_dom_node ( $dom->getElementsByTagName('tag') ) {
        my $tg = Tag->from_xml( $tag_dom_node->toString(0) );
        $tgs->append($tg);
    }

    return $tgs;
}

1;
