package Tag;

use strict;
use warnings;

use XML::Simple;
use XML::LibXML;

sub new {
    my $class = shift;
	my ( $descr ) = @_;

	return if( !defined _check_value($descr) );

	my $obj = \$descr;

    bless $obj , $class;
    return $obj;
}

sub value {
	my $self = shift;

    if (@_ && _check_value(@_)) { $$self = shift; }	

	return $$self;
}

sub toXML {
    my $self = shift;

    return "<tag>" . $$self . "</tag>";
}

sub from_xml {
    my $class = shift;
    my ( $xml ) = @_;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Resource DTD v0.01",
        "dtd/tag.dtd" );

    my $doc = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $doc ) || !$doc->is_valid($dtd) ) {

        # Validation failed
        return;
    }

    # XML is valid.
    my $tg = XMLin($xml);

	return if (!_check_value($tg));

    my $obj = \$tg;

    bless $obj, $class;
    return $obj;
}

sub _check_value {
	my ($val) = @_;
    return if ( !defined($val) );
	return if ( $val =~ /[^\w.:_\-]/ );
	return if ( length($val) < 4 || length($val) > 60 );
	return 1;
}

1;
