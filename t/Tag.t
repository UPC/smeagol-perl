#!/usr/bin/perl
use Test::More tests => 34;

use strict;
use warnings;

use XML::Simple;
use Data::Compare;
use Encode;

BEGIN {
    use_ok($_) for qw(Smeagol::Tag Smeagol::DataStore);

    Smeagol::DataStore::init();
}
use Data::Dumper;

my $tg;
my $val;
my $xml;

#create tag
{
    $tg = Smeagol::Tag->new();
    ok( !defined $tg, 'tag not created' );

    $tg = Smeagol::Tag->new();
    ok( !defined $tg, 'tag not created' );

    $tg = Smeagol::Tag->new("");
    ok( !defined $tg, 'tag not created, is empty' );

    $tg = Smeagol::Tag->new("987dcd  98");
    ok( !defined $tg, 'tag not created, there are spaces ' );

    $tg = Smeagol::Tag->new("CN");
    ok( defined $tg, 'tag created' );

    $tg = Smeagol::Tag->new(
        "aa333333333333333333333333333333333333333333333333333333asdfsdsaf");
    ok( !defined $tg, 'tag not created, too long' );

    $tg = Smeagol::Tag->new("-87d:c_d.98");
    ok( defined $tg, 'tag created' );

    $tg = Smeagol::Tag->new("-87dcd.98");
    ok( defined $tg, 'tag created' );

    $tg = Smeagol::Tag->new("asdf-87d:c_d.98");
    ok( defined $tg, 'tag created' );

    $tg = Smeagol::Tag->new("______");
    ok( defined $tg, 'tag created' );

}

#value
{

    $tg = Smeagol::Tag->new("aula");
    ok( defined $tg, 'tag created' );
    ok( "aula" eq $tg->value(), 'tag retrieved ' );

    $val = $tg->value("classe");
    ok( "classe" eq $val, 'tag updated' );

    $val = $tg->value();
    ok( "classe" eq $val, 'tag not updated' );

    $val = $tg->value("campus-nord");
    ok( "campus-nord" eq $val, 'tag updated' );

    $val = $tg->value("campus nord");
    ok( !defined $val, 'tag not updated, wrong value' );

    $val = $tg->value("campus:nord");
    ok( "campus:nord" eq $val, 'tag updated' );

    $val = $tg->value("c ");
    ok( !defined $val, 'tag not updated, bad chars' );
}

#to_xml
{
    $tg = Smeagol::Tag->new("projector");
    ok( defined $tg, 'created tag' );
    $xml = $tg->toXML();
    ok( '<tag>projector</tag>' eq $xml, 'Ok toXML' );

    $tg = Smeagol::Tag->new("aula.multimedia");
    ok( defined $tg, 'created tag' );
    $xml = $tg->toXML();
    ok( '<tag>aula.multimedia</tag>' eq $xml, 'Ok toXML' );
}

#from_xml
{
    $tg = Smeagol::Tag->from_xml("<tag>aula</tag>");
    ok( defined $tg, 'created tag from xml' );
    ok( $tg->value eq "aula", 'checked tag creation from xml' );

    $tg = Smeagol::Tag->from_xml("<tag>au la</tag>");
    ok( !defined $tg, 'not created tag from xml, wrong value' );

    $tg = Smeagol::Tag->from_xml("<tag>a</tag>");
    ok( !defined $tg, 'not created tag from xml, too short' );

    $tg = Smeagol::Tag->from_xml("<tag>campus+nord</tag>");
    ok( !defined $tg, 'not created tag from xml, wrong value' );

    $tg = Smeagol::Tag->from_xml("<tag>campus:nord-aula:S103</tag>");
    ok( defined $tg, 'created tag from xml' );
    ok( $tg->value eq "campus:nord-aula:S103",
        'checked tag creation from xml'
    );

}

# Tag in UTF-8
{
    my $encoding = "UTF-8";
    my $text     = decode( $encoding, "àèòéíóúïüçñ" );
    my $tag      = Smeagol::Tag->new($text);
    isa_ok( $tag, 'Smeagol::Tag' );
    is( $tag->value, $text, "value in UTF-8" );
    like( $tag->toXML, qr/$text/, "XML string in UTF-8" );
}

END { Smeagol::DataStore->clean() }
