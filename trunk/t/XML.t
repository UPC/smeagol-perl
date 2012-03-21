#!/usr/bin/perl

use Test::More tests => 11;

use strict;
use warnings;

BEGIN {
    use_ok($_) for qw(Smeagol::XML);
}

# simplest XML tests
{
    eval { Smeagol::XML->new() };
    isnt( $@, "", "undef XML fails" );

    eval { Smeagol::XML->new("") };
    isnt( $@, "", "empty XML fails" );

    my $xml = eval { Smeagol::XML->new("<foobar/>") };
    is( $@,        "",             "simplest XML works" );
    is( ref($xml), "Smeagol::XML", "blessed thy XML" );

    my $expected = qq{<?xml version="1.0" encoding="UTF-8"?>\n<foobar/>\n};
    is( "$xml", $expected, "simplest XML as expected" );

    $xml->addPreamble("foobar");
    $expected
        = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
        . qq{<?xml-stylesheet type="application/xml" href="/xsl/foobar.xsl"?>\n}
        . qq{<foobar/>\n};
    is( "$xml", $expected, "added preamble to simplest XML" );

    $xml->addXLink( "foobar", "http://foobar/foobar" );
    $expected
        = qq{<?xml version="1.0" encoding="UTF-8"?>\n}
        . qq{<?xml-stylesheet type="application/xml" href="/xsl/foobar.xsl"?>\n}
        . qq{<foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar"/>\n};
    is( "$xml", $expected, "added XLinks to simplest XML" );
};

# complex XML tests
{
    my $xml = eval {
        Smeagol::XML->new(<<'EndOfXML') };
<foobar>
    <foobar>
        <foobar>foobar</foobar>
        <foobar>foobar</foobar>
    </foobar>
    <foobar>
        <foobar>foobar</foobar>
        <foobar>foobar</foobar>
    </foobar>
</foobar>
EndOfXML
    is( $@,        "",             "complex XML works" );
    is( ref($xml), "Smeagol::XML", "blessed thy XML" );

    $xml->addPreamble("foobar");
    $xml->addXLink( "foobar", "http://foobar/foobar" );

    my $expected = do { local $/; <DATA> };
    is( "$xml", $expected, "complex XML worked miracles" );
};

__END__
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="application/xml" href="/xsl/foobar.xsl"?>
<foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">
    <foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">
        <foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">foobar</foobar>
        <foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">foobar</foobar>
    </foobar>
    <foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">
        <foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">foobar</foobar>
        <foobar xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="http://foobar/foobar">foobar</foobar>
    </foobar>
</foobar>
