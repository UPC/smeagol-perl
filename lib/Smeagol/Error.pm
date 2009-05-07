package Smeagol::Error;

use strict;
use warnings;

use XML::Simple;
use XML::LibXML;
use Carp;
use Smeagol::XML;
use Data::Dumper;

sub new {
    my $class = shift;
    my ($code, $descr) = @_;

    return if ( !$code || ! $descr );

    my $obj = {
		code => $code,
		description => $descr
	};

    bless $obj, $class;
    return $obj;
}

sub code {
    my $self = shift;

	if (@_) { $self->{code} = shift; }

	return $self->{code};

}

sub description {
    my $self = shift;

    if (@_) { $self->{description} = shift; }

    return $self->{description};
}

sub __str__ {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    my $xmlText = "<error><code>" .$self->code . "</code><description>" . $self->description . "</description></error>";

    return $xmlText
        unless defined $url;

    my $xmlDoc = eval { Smeagol::XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "error", $url . $self->url );
    if ($isRootNode) {
        $xmlDoc->addPreamble("error");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("error")->[0];
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
        = XML::LibXML::Dtd->new( "CPL UPC//Error DTD v0.01", "dtd/error.dtd" );

    my $doc = eval { XML::LibXML->new->parse_string($xml) };
    croak $@ if $@;

    if ( ( !defined $doc ) || !$doc->is_valid($dtd) ) {

        # Validation failed
        return;
    }

    # XML is valid.
    my $obj = {
		code =>
            $doc->getElementsByTagName('code')->string_value,

		description =>
            $doc->getElementsByTagName('description')->string_value,

	};

	return if ( !$obj->{code} || !$obj->{description} );

    bless $obj, $class;
    return $obj;
}

1;
