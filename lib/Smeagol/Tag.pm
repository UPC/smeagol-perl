package Smeagol::Tag;

use strict;
use warnings;

use XML::Simple;
use XML::LibXML;
use Carp;
use Smeagol::XML;
use Data::Dumper;

use overload
    q{""} => \&__str__,
    q{==} => \&__equal__,
    q{eq} => \&__equal__,
    q{!=} => \&__not_equal__,
    q{ne} => \&__not_equal__;

our $MIN = 2;
our $MAX = 60;

sub new {
    my $class = shift;
    my ($descr) = @_;

    return if ( !defined _check_value($descr) );

    my $obj = \$descr;

    bless $obj, $class;
    return $obj;
}

sub value {
    my $self = shift;

    return if ( @_ && !_check_value(@_) );
    $$self = shift if ( @_ && _check_value(@_) );

    return $$self;
}

sub intersects {
    my $self = shift;
    my ($tag) = @_;

    return $self->value eq $tag->value;
}

sub url {
    my $self = shift;

    return "/tag/" . $self->value;
}

sub __equal__ {
    my $self = shift;
    my ($tag) = @_;

    croak "invalid reference"
        unless ref($tag) eq __PACKAGE__;

    return $self->value eq $tag->value;
}

sub __not_equal__ {
    return !shift->__equal__(@_);
}

sub __str__ {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $xmlText = "<tag>" . $self->value . "</tag>";

    return $xmlText
        unless defined $url;

    my $xmlDoc = eval { Smeagol::XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "tag", $url . $self->url );
    if ($isRootNode) {
        $xmlDoc->addPreamble("tag");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("tag")->[0];
        return $node->toString;
    }
}

sub toXML {
    return shift->__str__(@_);
}

sub from_xml {
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

    # XML is valid.
    my $tg;
    if ( ref( XMLin($xml) ) eq 'HASH' ) {
        $tg = XMLin( $xml, SuppressEmpty => '' )->{content};
    }
    else {
        $tg = XMLin( $xml, SuppressEmpty => '' );
    }

    return if ( !_check_value($tg) );

    my $obj = \$tg;

    bless $obj, $class;
    return $obj;
}

sub _check_value {
    my ($val) = @_;
    return if ( !defined($val) );
    return if ( $val =~ /[^\w.:_\-]/ );
    return if ( length($val) < $MIN || length($val) > $MAX );
    return 1;
}

1;
