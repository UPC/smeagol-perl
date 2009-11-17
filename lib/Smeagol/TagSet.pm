package Smeagol::TagSet;

use strict;
use warnings;

use Set::Object ();
use base qw(Set::Object);
use Smeagol::Tag;
use Data::Dumper;
use Smeagol::XML;
use Carp;

use overload q{""} => \&toString;

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
    return $obj;
}

sub append {
    my $self = shift;
    my ($tag) = @_;

    ( defined $tag ) or die "SetTag->append requires one parameter";

    $self->insert($tag) unless $self->findValue( $tag->value );
}

sub findValue {
    my $self = shift;
    my ($value) = @_;

    #FIXME 136: utilitzar caller per obtenir el nom de la funcio
    croak "TagSet->findValue requires one parameter"
        unless defined $value;

    return grep { $value eq $_->value } $self->elements;
}

sub toSmeagolXML {
    my $self        = shift;
    my $xlinkPrefix = shift;

    my $url;
    $url = $xlinkPrefix . $self->url if defined $xlinkPrefix;

    my $result = eval { Smeagol::XML->new("<tags/>") };
    croak $@ if $@;

    my $tagSetNode = $result->doc->documentElement;

    for my $tag ( $self->elements ) {
        my $tagNode = $tag->toSmeagolXML($xlinkPrefix)->doc->documentElement();
        $result->doc->adoptNode($tagNode);
        $tagSetNode->appendChild($tagNode);
    }
    
    if ( defined $xlinkPrefix ) {
        $result->addXLink( "tags", $xlinkPrefix );
    }

    return $result;
}

sub url {
    return "/tags";
}

# No special order is granted in results, because of Set->elements behaviour.
sub toString {
    my $self = shift;
    my $url  = shift;

    my $dom = $self->toSmeagolXML($url);

    if ( defined $url ) {
        $dom->addXLink( "tags", $url . "/tags" );
    }

    return $dom->toString;

    # FIXME: Perhaps the $isRootNode variable is superfluous when using
    #        XML::LibXML (see comment in "toString" method, in
    #        Smeagol/Booking.pm source file), so the following lines
    #        could be definively removed

    #if ($isRootNode) {
    #    $xmlDoc->addPreamble("tags");
    #    return "$xmlDoc";
    #}
    #else {
    #    # Take the first node and skip processing instructions
    #    my $node = $xmlDoc->doc->getElementsByTagName("tags")->[0];
    #    return $node->toString;
    #}
}

sub toXML {
    return shift->toString(@_);
}

sub newFromXML {
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

    my $tagSet = $class->SUPER::new();
    bless $tagSet, $class;

    # traverse all '<tag>' elements found in DOM structure.
    for my $node ( $dom->getElementsByTagName('tag') ) {
        my $tag = Smeagol::Tag->newFromXML( $node->toString );
        $tagSet->append($tag);
    }

    return $tagSet;
}

1;
