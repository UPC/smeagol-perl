#!perl

use strict;
use warnings;

BEGIN {
    require 't/TestingDB.pl';
}

use V2::Test;
use Test::More;
use utf8::all;

my $t = V2::Test->new( uri => '/tag' );

my @tags = $t->GET();

is_deeply( \@tags, [], 'get empty list of tags' );

my %tag1 = (
    id          => 'tag-name',
    description => 'tag-description',
);

my $id  = $t->POST( args => \%tag1 );
my $out = $t->GET( id => $id );

is_deeply( $out, \%tag1, "create tag1" );

@tags = $t->GET();

is_deeply( \@tags, [ $id ], 'list of 1 tag' );

$tag1{'description'} = 'edited';

$t->PUT( id => $id, args => \%tag1 );

@tags = $t->GET();

is_deeply( \@tags, [ $id ], 'still list of 1 tag' );

$out = $t->GET( id => $id );

is_deeply( $out, \%tag1, "edit tag1" );

$t->DELETE( id => $id );

@tags = $t->GET();

is_deeply( \@tags, [], 'delete gets empty list back' );

done_testing();
