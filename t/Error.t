#!/usr/bin/perl
use Test::More tests => 14;

use strict;
use warnings;

use XML::Simple;
use Data::Compare;
use Encode;
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(Smeagol::Error Smeagol::DataStore);
}

my ($er, $xml , $xml2);

#creating errors
{
	$er = Smeagol::Error->new(400, 'Conflict');
	ok( defined $er 
		&& $er->code eq '400' 
		&& $er->description eq 'Conflict', 'created error');
	
	$er = Smeagol::Error->new('', 'Conflict');
	ok( !defined $er , 'Error not created, code not defined');

	$er = Smeagol::Error->new('400', '');
	ok( !defined $er , 'Error not created, description not defined');
}

#creating from xml
{
	$er = Smeagol::Error->from_xml('<error><code>400</code><description>Conflict</description></error>');
	ok( defined $er 
		&& $er->code eq '400' 
		&& $er->description eq 'Conflict', 'created error from xml');

	$er = Smeagol::Error->from_xml('<error><code></code><description>Conflict</description></error>');
	ok( !defined $er, 'not created error from xml, code not defined');

	$er = Smeagol::Error->from_xml('<error><code>400</code><description></description></error>');
	ok( !defined $er, 'not created error from xml, code not defined');
}

#consulting code and description
{
	$er = Smeagol::Error->new(400, 'Conflict');
	ok( defined $er 
		&& $er->code eq '400' 
		&& $er->description eq 'Conflict', 'created error');

	$er = Smeagol::Error->new(401, 'Conflict');
	ok( defined $er 
		&& $er->code eq '401' 
		&& $er->description eq 'Conflict', 'created error');

	$er->code(404);
	ok( $er->code() eq '404' 
		&& $er->description eq 'Conflict', 'updated code');

	$er->description('Not found');
	ok( $er->description() eq 'Not found' 
		&& $er->code eq '404', 'updated description');
}

#checking to_xml
{
	$xml = '<error><code>400</code><description>Not found</description></error>';

	$er = Smeagol::Error->from_xml($xml);
	ok( defined $er, 'created error');

	$xml2 = $er->toXML();
	ok($xml eq $xml2, 'error to xml ok');
}

END { Smeagol::DataStore->clean() }
