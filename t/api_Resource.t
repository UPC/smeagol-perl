#!perl

use strict;
use warnings;
use utf8::all;

use Test::More;
use HTTP::Request::Common qw( GET POST PUT DELETE );

my %tests = (
    {
        op  => 'POST',
        uri => '/resource',
        # entrada => 'description=DESCRIPTION',
        entrada => {
            description => 'aula',
            info => 'resource info',
        },
        # sortida => '{"id":*,"description":"DESCRIPTION","info":""}',
        sortida => {
            description => 'aula',
            info       => 'resource info',
        },
    },
    {
        op => 'GET',
        uri => '/resource',
        entrada => {
            descripcio => 'aula',
        },
        sortida => {
            descripcio => 'aula',
            info       => '',
        },
    },
);

my %helpers = (
    GET => \&consulta_recurs,
    POST => \&crea_recurs,
);

for my $t (@tests) {
    test_smeagol_resource($t);
}

sub test_smeagol_resource {
    my ($id) = crea_recurs();
    like( $id, /\d+/, "id ben format" );
    my %recurs = $helpers{ $t->{'op'} }->( $t->{'entrada'} );
    is( $recurs{'description'}, $t->{'sortida'}{'description'}, "desc" );
}

sub llista_ids_abans {
    # GET /resource
    return qw( 1 2 3 );
}

sub llista_ids_despres {
    # GET /resource
    return qw( 1 2 3 4 );
}

sub crea_recurs {
    my @abans = llista_ids_abans();
    # POST /resource ...
    my @despres = llista_ids_despres();

    my $id = 4;

    return $id;
}

sub consulta_recurs {
}
