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

$t->POST( { id => 'tag1' } );
$t->POST( { id => 'tag2' } );

my $r = V2::Test->new( uri => '/resource' );

my @resources = $r->GET();

is_deeply( \@resources, [], 'get empty list of resources' );

my %res1 = (
    description => 'resource1',
    info        => 'info1',
);


# FIXME (bug #355)
#
# Actualment es poden passar tags a la creació però l'objecte
# retornat no els té perquè es consideren atributs derivats,
# per tant potser també caldria forçar l'assignació dels tags
# via API? e.g. POST /resource/1/tag
#
my $id  = $r->POST([ %res1, tags => 'tag1,tag2' ]);
my $out = $r->GET($id);

is_deeply( $out, { %res1, id => $id }, "create res1" );

@resources = $r->GET();

is_deeply( \@resources, [ $id ], 'list of 1 resource' );

$res1{'description'} = 'edited';

# FIXME (bug #355)
#
# Es pot considerar un PUT de tipus REST si no es passen
# tots els atributs de l'objecte?
#
# $r->PUT( $id, [ %res1, tags => '' ] );
$r->PUT( $id, [ %res1 ] );

@resources = $r->GET();

is_deeply( \@resources, [ $id ], 'still list of 1 resource' );

$out = $r->GET($id);

is_deeply( $out, { %res1, id => $id }, "edit res1" );

$r->DELETE($id);

@resources = $r->GET();

is_deeply( \@resources, [], 'delete gets empty list back' );

done_testing();
