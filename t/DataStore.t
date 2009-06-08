#!/usr/bin/perl
use Test::More tests => 16;

use strict;
use warnings;
use Data::Dumper;

use Carp;

BEGIN {
    use_ok($_) for qw(Smeagol::DataStore);

    Smeagol::DataStore::init();
}

my @ids = Smeagol::DataStore->getIDList;
ok( @ids == 0, 'testing getIDList with empty DataStore' );

my $id = Smeagol::DataStore->getNextID('TEST');
ok( $id == 1, 'testing getNextID with empty DataStore' );

my $obj = "Hello, I am an object!";
Smeagol::DataStore->save( $id, $obj );
my $obj2 = Smeagol::DataStore->load($id);
ok( $obj2 eq $obj,
    'testing object saving and retrieving with just one object in DataStore'
);

@ids = Smeagol::DataStore->getIDList;
ok( @ids == 1, 'testing getIDList with one object in DataStore' );

$id = Smeagol::DataStore->getNextID('TEST');
ok( $id == 2, 'testing getNextID with one object in DataStore' );

Smeagol::DataStore->save( Smeagol::DataStore->getNextID('TEST'), $obj );
@ids = Smeagol::DataStore->getIDList;
ok( @ids == 2, 'testing getIDList with two objects in DataStore' );

Smeagol::DataStore->save( Smeagol::DataStore->getNextID('TEST'), $obj );
@ids = Smeagol::DataStore->getIDList;
ok( @ids == 3, 'testing getIDList with three objects in DataStore' );

my $exist3 = Smeagol::DataStore->exists(3);
ok( $exist3, 'exists object' );

my $exist2 = Smeagol::DataStore->exists(125);
ok( !$exist2, "doesn't exist object" );

Smeagol::DataStore->remove(3);
$exist3 = Smeagol::DataStore->exists(3);
ok( !$exist3, "doesn't exist an object removed" );

$id = Smeagol::DataStore->getNextID('TEST');
ok( $id == 5, 'next_id after removing' );

Smeagol::DataStore->save( Smeagol::DataStore->getNextID('TEST'), $obj );
@ids = Smeagol::DataStore->getIDList;
ok( @ids == 3, 'testing getIDList with three objects in DataStore' );

$id = Smeagol::DataStore->getNextID('TEST');
ok( $id == 7, 'getNextID after saving' );

my $object = "Hello, I am another object!";
Smeagol::DataStore->save( $id, $object );
@ids = Smeagol::DataStore->getIDList;
ok( @ids == 4, 'getIDList after removing and saving' );

Smeagol::DataStore->remove($id);
$obj = Smeagol::DataStore->load($id);
ok( !defined $obj, 'retrieval after removal' );

END {
    Smeagol::DataStore->clean();
}
