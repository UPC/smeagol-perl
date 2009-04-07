#!/usr/bin/perl
use Test::More tests => 31;

use strict;
use warnings;

use XML::Simple;
use Data::Compare;

BEGIN {

    #
    # FIXME: Purge the hard way until DataStore does it better
    #
    unlink glob "/tmp/smeagol_datastore/*";

    use_ok($_) for qw(Tag DataStore);
}
use Data::Dumper;

my $tg;
my $val;
my $xml;

#create tag
{
	$tg = Tag->new();
	ok( !defined $tg, 'tag not created');

	$tg = Tag->new();
	ok( !defined $tg, 'tag not created' );

	$tg = Tag->new("");
	ok( !defined $tg, 'tag not created, is empty');

	$tg = Tag->new("987dcd  98");
	ok( !defined $tg, 'tag not created, there are spaces ');

	$tg = Tag->new("as");
	ok( !defined $tg, 'tag not created, too short' );

	$tg = Tag->new("aa333333333333333333333333333333333333333333333333333333asdfsdsaf");
	ok( !defined $tg, 'tag not created, too long' );

	$tg = Tag->new("-87d:c_d.98");
	ok( defined $tg, 'tag created' );

	$tg = Tag->new("-87dcd.98");
	ok( defined $tg, 'tag created' );

	$tg = Tag->new("asdf-87d:c_d.98");
	ok( defined $tg, 'tag created' );

	$tg = Tag->new("______");
	ok( defined $tg, 'tag created' );

}

#value
{

	$tg = Tag->new("aula");
	ok(defined $tg, 'tag created' );
	ok("aula" eq $tg->value(), 'tag retrieved ');

	$val = $tg->value("classe");
	ok("classe" eq $val, 'tag updated');

	$val = $tg->value();
	ok("classe" eq $val, 'tag not updated');

	$val = $tg->value("campus-nord");
	ok("campus-nord" eq $val, 'tag updated');

	$val = $tg->value("campus nord");
	ok("campus nord" ne $val, 'tag not updated, wrong value');

	$val = $tg->value("campus:nord");
	ok("campus:nord" eq $val, 'tag updated');

	$val = $tg->value("cn");
	ok("cn" ne $val, 'tag not updated,too short');
}


#to_xml
{
	$tg = Tag->new("projector");
	ok(defined $tg, 'created tag');
	$xml = $tg->toXML();
	ok('<tag>projector</tag>' eq $xml, 'Ok toXML');

	$tg = Tag->new("aula.multimedia");
	ok(defined $tg, 'created tag');
	$xml = $tg->toXML();
	ok('<tag>aula.multimedia</tag>' eq $xml, 'Ok toXML');
}

#from_xml
{
	$tg = Tag->from_xml("<tag>aula</tag>");
	ok(defined $tg, 'created tag from xml');
	ok($tg->value eq "aula", 'checked tag creation from xml');

	$tg = Tag->from_xml("<tag>au la</tag>");
	ok(!defined $tg, 'not created tag from xml, wrong value');

	$tg = Tag->from_xml("<tag>aul</tag>");
	ok(!defined $tg, 'not created tag from xml, too short');

	$tg = Tag->from_xml("<tag>campus+nord</tag>");
	ok(!defined $tg, 'not created tag from xml, wrong value');

	$tg = Tag->from_xml("<tag>campus:nord-aula:S103</tag>");
	ok(defined $tg, 'created tag from xml');
	ok($tg->value eq "campus:nord-aula:S103", 'checked tag creation from xml');

}

END { DataStore->clean() }
