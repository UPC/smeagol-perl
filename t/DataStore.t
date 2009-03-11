#!/usr/bin/perl
use Test::More tests => 16;

use strict;
use warnings;
use Data::Dumper;

use Carp;

BEGIN {
    unlink glob "/tmp/smeagol_datastore/*";
    use_ok($_) for qw(DataStore);
}

# Testing DataStore->list_id() with empty DataStore
my @ids = DataStore->list_id;
ok( @ids == 0, 'testing list_id with empty DataStore' );

# Testing DataStore->next_id with empty DataStore
my $id = DataStore->next_id('TEST');
ok( $id == 1, 'testing next_id with empty DataStore' );

# Testing object saving and retrieving
my $obj = "Hello, I am an object!";
DataStore->save( $id, $obj );
my $obj2 = DataStore->load($id);
ok( $obj2 eq $obj,
    'testing object saving and retrieving with just one object in DataStore' );

# Testing list_id with one object in DataStore
@ids = DataStore->list_id;
ok( @ids == 1, 'testing list_id with one object in DataStore' );

# Testing DataStore->nest_id with one object in DataStore
$id = DataStore->next_id('TEST');
ok( $id == 2, 'testing next_id with one object in DataStore' );

DataStore->save( DataStore->next_id('TEST'), $obj );
@ids = DataStore->list_id;
ok( @ids == 2, 'testing list_id with two objects in DataStore' );

DataStore->save( DataStore->next_id('TEST'), $obj );
@ids = DataStore->list_id;
ok( @ids == 3, 'testing list_id with three objects in DataStore' );

# Testing DataStore->exist
my $exist3 = DataStore->exists(3);
ok( $exist3, 'exists object' );

my $exist2 = DataStore->exists(125);
ok( !$exist2, "doesn't exist object" );

# Testing DataStore->remove
DataStore->remove(3);
$exist3 = DataStore->exists(3);
ok( !$exist3, "doesn't exist an object removed" );

$id = DataStore->next_id('TEST');
ok( $id == 5, 'next_id after removing' );

DataStore->save( DataStore->next_id('TEST'), $obj );
@ids = DataStore->list_id;
ok( @ids == 3, 'testing list_id with three objects in DataStore' );

$id = DataStore->next_id('TEST');
ok( $id == 7, 'next_id after saving' );

my $object = "Hello, I am another object!";
DataStore->save( $id, $object );
@ids = DataStore->list_id;
ok( @ids == 4, 'list_id after removing and saving' );

DataStore->remove($id);
$obj = DataStore->load($id);
ok( !defined $obj, 'retrieval after removal' );

END {
    DataStore->clean();
}
