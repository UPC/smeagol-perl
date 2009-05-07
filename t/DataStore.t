#!/usr/bin/perl
use Test::More tests => 16;

use strict;
use warnings;
use Data::Dumper;

use Carp;

BEGIN {
    use_ok($_) for qw(Smeagol::DataStore);

    Smeagol::DataStore::init('/tmp/smeagol_datastore');
}

# Testing DataStore->list_id() with empty DataStore
my @ids = Smeagol::DataStore->list_id;
ok( @ids == 0, 'testing list_id with empty DataStore' );

# Testing DataStore->next_id with empty DataStore
my $id = Smeagol::DataStore->next_id('TEST');
ok( $id == 1, 'testing next_id with empty DataStore' );

# Testing object saving and retrieving
my $obj = "Hello, I am an object!";
Smeagol::DataStore->save( $id, $obj );
my $obj2 = Smeagol::DataStore->load($id);
ok( $obj2 eq $obj,
    'testing object saving and retrieving with just one object in DataStore'
);

# Testing list_id with one object in DataStore
@ids = Smeagol::DataStore->list_id;
ok( @ids == 1, 'testing list_id with one object in DataStore' );

# Testing DataStore->nest_id with one object in DataStore
$id = Smeagol::DataStore->next_id('TEST');
ok( $id == 2, 'testing next_id with one object in DataStore' );

Smeagol::DataStore->save( Smeagol::DataStore->next_id('TEST'), $obj );
@ids = Smeagol::DataStore->list_id;
ok( @ids == 2, 'testing list_id with two objects in DataStore' );

Smeagol::DataStore->save( Smeagol::DataStore->next_id('TEST'), $obj );
@ids = Smeagol::DataStore->list_id;
ok( @ids == 3, 'testing list_id with three objects in DataStore' );

# Testing DataStore->exist
my $exist3 = Smeagol::DataStore->exists(3);
ok( $exist3, 'exists object' );

my $exist2 = Smeagol::DataStore->exists(125);
ok( !$exist2, "doesn't exist object" );

# Testing DataStore->remove
Smeagol::DataStore->remove(3);
$exist3 = Smeagol::DataStore->exists(3);
ok( !$exist3, "doesn't exist an object removed" );

$id = Smeagol::DataStore->next_id('TEST');
ok( $id == 5, 'next_id after removing' );

Smeagol::DataStore->save( Smeagol::DataStore->next_id('TEST'), $obj );
@ids = Smeagol::DataStore->list_id;
ok( @ids == 3, 'testing list_id with three objects in DataStore' );

$id = Smeagol::DataStore->next_id('TEST');
ok( $id == 7, 'next_id after saving' );

my $object = "Hello, I am another object!";
Smeagol::DataStore->save( $id, $object );
@ids = Smeagol::DataStore->list_id;
ok( @ids == 4, 'list_id after removing and saving' );

Smeagol::DataStore->remove($id);
$obj = Smeagol::DataStore->load($id);
ok( !defined $obj, 'retrieval after removal' );

END {
    Smeagol::DataStore->clean();
}
