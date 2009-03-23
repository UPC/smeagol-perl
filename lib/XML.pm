package XML;

use strict;
use warnings;

use XML::LibXML;
use Carp;

use overload q{""} => \&__str__;

sub new {
    my $class = shift;
    my ($xml) = @_;

    my $parser = XML::LibXML->new();
    my $doc = eval { $parser->parse_string($xml) };
    croak "cannot parse XML document: $@"
        if $@;

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

sub __str__ {
    return shift->{xmldoc}->toString();
}

1;
