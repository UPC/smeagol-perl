#!/usr/bin/perl
use Test::More tests => 7;

use strict;
use warnings;
use Data::Dumper;

use Carp;

BEGIN { use_ok($_) for qw(DataStore) }

# Testing DataStore->list_id() with empty DataStore
my @ids = DataStore->list_id;
ok($#ids == -1, 'testing list_id with empty DataStore');

# Testing DataStore->next_id with empty DataStore
my $id = DataStore->next_id('TEST');
ok($id == 1, 'testing next_id with empty DataStore');

# Testing object saving and retrieving
my $obj = "Hello, I am an object!";
DataStore->save(1, $obj);
my $obj2 = DataStore->load(1);
ok($obj2 eq $obj, 'testing object saving and retrieving with just one object in DataStore');

# Testing list_id with one object in DataStore
@ids = DataStore->list_id;
ok($#ids == 0, 'testing list_id with one object in DataStore');

# Testing DataStore->nest_id with one object in DataStore
$id = DataStore->next_id('TEST');
ok($id == 2, 'testing next_id with one object in DataStore');

DataStore->save(DataStore->next_id('TEST'), $obj);
@ids = DataStore->list_id;
carp Dumper(@ids);
ok($#ids == 1, 'testing list_id with two objects in DataStore');


END {
    DataStore->clean();
}
