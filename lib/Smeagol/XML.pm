package Smeagol::XML;

use strict;
use warnings;

use XML::LibXML;
use Carp;
use Data::Dumper;

use overload q{""} => \&toString;

sub new {
    my $class = shift;
    my ($xml) = @_;

    my $parser = XML::LibXML->new();
    my $doc = eval { $parser->parse_string($xml) };
    croak "cannot parse XML document: $@"
        if $@;

    $doc->setEncoding('UTF-8');

    my $obj = {
        parser => $parser,
        xmldoc => $doc,
    };

    bless $obj, $class;
    return $obj;
}

sub parser {
    return shift->{parser};
}

sub doc {
    return shift->{xmldoc};
}

sub addPreamble {
    my $self = shift;
    my ($type) = @_;

    my $doc = $self->doc;
    $doc->setEncoding('UTF-8');

    my $pi = $doc->createPI( 'xml-stylesheet',
        qq{type="application/xml" href="/xsl/$type.xsl"} );

    $doc->insertBefore( $pi, $doc->firstChild );
}

sub addXLink {
    my $self = shift;
    my ( $name, $url ) = @_;

    my @nodes = $self->doc->getElementsByTagName($name);

    for my $node (@nodes) {
        $node->setNamespace( "http://www.w3.org/1999/xlink", "xlink", 0 );
        $node->setAttribute( "xlink:type", 'simple' );
        $node->setAttribute( "xlink:href", $url );
    }
}

# removes all XLink-related attributes (xmlns:xlink, xlink:type, xlink:href)
#
sub removeXLink {
    my $class  = shift;
    my $xmlStr = shift;

    my $parser = XML::LibXML->new();
    my $doc = eval { $parser->parse_string($xmlStr) };
    croak "cannot parse XML document: $@" if $@;

    my $compiled_xpath = XML::LibXML::XPathExpression->new('//*');

    my @nodes = $doc->findnodes($compiled_xpath);

    for my $node (@nodes) {
        $node->removeAttributeNS( 'http://www.w3.org/1999/xlink', 'xlink' );
        $node->removeAttribute('xlink:type');
        $node->removeAttribute('xlink:href');
    }
    my $string = $doc->toString ;
    $string =~ s/xmlns:xlink="http:\/\/www\.w3\.org\/1999\/xlink"//g;
    return $string;
}

sub toString {
    return shift->{xmldoc}->toString();
}

1;
