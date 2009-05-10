#!/usr/bin/perl
use Test::More tests => 53;

use strict;
use warnings;

use XML::Simple;
use Data::Compare;

BEGIN {
    use_ok($_) for qw(
        Smeagol::Tag
        Smeagol::TagSet
        Smeagol::DataStore
    );

    Smeagol::DataStore::init();
}
use Data::Dumper;

my $tgS;
my ( $tg1, $tg2, $tg3, $tg4, $tg5 );
my ( $xmlTg1, $xmlTg5, $xmlTgS );

$tg1 = Smeagol::Tag->new("aula");
ok( defined $tg1, 'tag created' );
ok( $tg1->value eq "aula", 'tag checked' );

$tg2 = Smeagol::Tag->new("campus:nord");
ok( defined $tg2, 'tag created' );
ok( $tg2->value eq "campus:nord", 'tag checked' );

$tg3 = Smeagol::Tag->new("S-345");
ok( defined $tg3, 'tag created' );
ok( $tg3->value eq "S-345", 'tag checked' );

$tg4 = Smeagol::Tag->new("projeeector");
ok( defined $tg4, 'tag created' );
ok( $tg4->value eq "projeeector", 'tag checked' );

$tg5 = Smeagol::Tag->new("projector");
ok( defined $tg5, 'tag created' );
ok( $tg5->value eq "projector", 'tag checked' );

#create tagSet
{
    $tgS = Smeagol::TagSet->new();
    ok( defined $tgS, 'tagSet created' );
}

#appending and removing tags
{

    $tgS = Smeagol::TagSet->new();
    ok( defined $tgS, 'tagSet created' );

    ok( $tgS->size == 0, 'tgS contains 0 tags' );

    ok( !$tgS->contains($tg1), 'tg1 not in tgS' );
    $tgS->append($tg1);
    ok( $tgS->contains($tg1), 'tg1 in tgS' );

    ok( !$tgS->contains($tg2), 'tg2 not in tgS' );
    $tgS->append($tg2);
    ok( $tgS->contains($tg2), 'tg2 in tgS' );

    ok( $tgS->size == 2, 'tgS contains 2 tags' );

    ok( !$tgS->contains($tg3), 'tg3 not in tgS' );
    $tgS->append($tg3);
    ok( $tgS->contains($tg3), 'tg3 in tgS' );

    ok( !$tgS->contains($tg4), 'tg4 not in tgS' );
    $tgS->append($tg4);
    ok( $tgS->contains($tg4), 'tg4 in tgS' );

    ok( !$tgS->contains($tg5), 'tg5 not in tgS' );
    $tgS->append($tg5);
    ok( $tgS->contains($tg5), 'tg5 in tgS' );

    ok( $tgS->size == 5, 'tgS contains 5 tags' );

    $tgS->remove($tg4);
    ok( !$tgS->contains($tg4), 'tg4 not in tgS' );

    $tgS->remove($tg1);
    ok( !$tgS->contains($tg1), 'tg1 not in tgS' );
    ok( $tgS->size == 3,       'tgS contains 3 tags' );
}

#to_xml
{
    $tgS = Smeagol::TagSet->new();
    ok( defined $tgS, 'tagSet created' );

    ok( $tgS->size == 0, 'tgS contains 0 tags' );

    ok( !$tgS->contains($tg1), 'tg1 not in tgS' );
    $tgS->append($tg1);
    ok( $tgS->contains($tg1), 'tg1 in tgS' );

    ok( $tgS->size == 1, 'tgS contains 1 tags' );

    $xmlTgS = $tgS->to_xml();
    ok( defined $xmlTgS, 'to_xml ok' );
    ok( $xmlTgS eq "<tags><tag>aula</tag></tags>", 'to_xml checked' );

    ok( !$tgS->contains($tg5), 'tg5 not in tgS' );
    $tgS->append($tg5);
    ok( $tgS->contains($tg5), 'tg5 in tgS' );

    ok( $tgS->size == 2, 'tgS contains 2 tags' );

    $xmlTgS = $tgS->to_xml();
    ok( defined $xmlTgS, 'to_xml ok' );
    ok( $xmlTgS        =~ /<tag>aula<\/tag>/
            && $xmlTgS =~ /<tag>projector<\/tag>/
            && $xmlTgS =~ /^<tags>/
            && $xmlTgS =~ /<\/tags>$/,
        'to_xml checked'
    );

    $tgS->remove($tg1);
    ok( !$tgS->contains($tg1), 'tg1 not in tgS' );

    $xmlTgS = $tgS->to_xml();
    ok( defined $xmlTgS, 'to_xml ok' );
    ok( $xmlTgS eq "<tags><tag>projector</tag></tags>", 'to_xml checked' );
}

#from_xml
{
    $xmlTg1 = $tg1->toXML();
    $xmlTg5 = $tg5->toXML();
    $xmlTgS = "<tags>" . $xmlTg1 . "</tags>";

    $tgS = Smeagol::TagSet->from_xml($xmlTgS);
    ok( defined $tgS,    'tagSet created' );
    ok( $tgS->size == 1, 'tgS contains 1 tag' );

    my ($tg) = $tgS->elements;
    ok( $tg->value eq $tg1->value, 'tag checked' );

    $xmlTgS = "<tags>" . $xmlTg1 . $xmlTg5 . "</tags>";

    $tgS = Smeagol::TagSet->from_xml($xmlTgS);
    ok( defined $tgS,    'tagSet created' );
    ok( $tgS->size == 2, 'tgS contains 2 tag' );

    $xmlTgS = $tgS->to_xml();
    ok( defined $xmlTgS, 'to_xml ok' );
    ok( $xmlTgS        =~ /<tag>aula<\/tag>/
            && $xmlTgS =~ /<tag>projector<\/tag>/
            && $xmlTgS =~ /^<tags>/
            && $xmlTgS =~ /<\/tags>$/,
        'to_xml checked'
    );
}

END { Smeagol::DataStore->clean() }
