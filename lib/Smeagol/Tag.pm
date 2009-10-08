package Smeagol::Tag;

use strict;
use warnings;

use XML::LibXML;
use Carp;
use Smeagol::XML;

use overload
    q{""} => \&toString,
    q{==} => \&isEqual,
    q{eq} => \&isEqual,
    q{!=} => \&isNotEqual,
    q{ne} => \&isNotEqual;

our $MIN = 2;
our $MAX = 60;

sub new {
    my $class = shift;
    my ($value) = @_;

    return if ( !defined _checkValue($value) );

    my $obj = \$value;

    bless $obj, $class;
    return $obj;
}

sub value {
    my $self = shift;

    return if ( @_ && !_checkValue(@_) );
    $$self = shift if ( @_ && _checkValue(@_) );

    return $$self;
}

sub url {
    my $self = shift;

    return "/tag/" . $self->value;
}

sub isEqual {
    my $self = shift;
    my ($tag) = @_;

    croak "invalid reference"
        unless ref($tag) eq __PACKAGE__;

    return $self->value eq $tag->value;
}

sub isNotEqual {
    return !shift->isEqual(@_);
}

# Build XML DOM tree representation of tag
sub toDOM {
    my $self = shift;

    my $dom = XML::LibXML::Document->new( '1.0', 'UTF-8' );
    my $tagNode = $dom->createElement('tag');
    $tagNode->appendText( $self->value );
    $dom->setDocumentElement($tagNode);

    return $dom;
}

sub toString {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $dom = $self->toDOM;

    return $dom->toString unless defined $url;

    $dom->addXLink( "tag", $url . $self->url );

    return "$dom";

 # TODO: I believe that the $isRootNode variable is superfluous when
 #       using XML::LibXML methods, because the toString method in that module
 #       automagically adds the XML preamble when needed, so I'll leave the
 #       following lines commented out, but won't remove them for now. (angel)

    #if ($isRootNode) {
    #    $xmlDoc->addPreamble("tag");
    #    return "$xmlDoc";
    #}
    #else {
    # Take the first node and skip processing instructions
    #    my $node = $xmlDoc->doc->getElementsByTagName("tag")->[0];
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
    my $dtd
        = XML::LibXML::Dtd->new( "CPL UPC//Tag DTD v0.01", "dtd/tag.dtd" );

    my $doc = eval { XML::LibXML->new->parse_string($xml) };
    croak $@ if $@;

    if ( ( !defined $doc ) || !$doc->is_valid($dtd) ) {

        # Validation failed
        return;
    }

    my $tagValue = $doc->findvalue('/tag');

    return if ( !_checkValue($tagValue) );

    my $obj = \$tagValue;

    bless $obj, $class;
    return $obj;
}

sub _checkValue {
    my ($value) = @_;
    return if ( !defined($value) );
    return if ( $value =~ /[^\w.:_\-]/ );
    return if ( length($value) < $MIN || length($value) > $MAX );
    return 1;
}

1;
