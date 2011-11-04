#!perl

use strict;
use warnings;
use utf8::all;

use Test::More;
use HTTP::Request::Common qw( GET POST PUT DELETE );
use HTTP::Status qw(:constants :is status_message);
use Data::Dumper::Simple;
use JSON;

BEGIN {
    require 't/TestingDB.pl';
    use_ok 'Catalyst::Test' => 'V2::Server';
}

# Cada test ve definit per aquesta estructura:
#
# {
#   op      => operador (GET, POST, PUT, DELETE),
#   uri     => la url (p.ex. /resource/NN),
#   entrada => [ nom_parametre1 => val, nom_param2 => val2, ... ],
#   sortida => {
#                 status => HTTP status,
#                 headers => { header1 => val1, ... },
#                 body => json string
#              },
# }

my @tests = (
    {    # Crear un nou recurs
        op      => 'POST',
        uri     => '/resource',
        entrada => {
            description => 'aula',
            info        => 'resource info',
        },
        sortida => {
            status  => HTTP_CREATED,
            headers => { Location => qr{/resource/\d+} },
            body    => {
                id          => qr/\d+/,
                description => 'aula',
                info        => 'resource info',
            },
        },
    },
);

my %helpers = (
    GET    => \&consulta_recurs,
    POST   => \&crea_recurs,
    UPDATE => \&modifica_recurs,
    DELETE => \&esborra_recurs,
);

for my $t (@tests) {
    test_smeagol_resource($t);
}

done_testing();


sub test_smeagol_resource {
    my ($test) = @_;
    my ($id)   = crea_recurs();
    like( $id, qr/\d+/, "id ben format" );
    my $sub    = $helpers{ $test->{'op'} };
    my $result = $sub->( $test->{'entrada'} );

    #is( $test->{entrada}, $test->{'sortida'}{'description'}, "desc" );
}

sub llista_ids_abans {
    my $rp = request( GET('/resource') );
    
    return parse_resource_ids($rp->content);
}

sub llista_ids_despres {

    # GET '/resource'
    return qw( 1 2 3 4 );
}

sub crea_recurs {
    my @abans = llista_ids_abans();

    # POST '/resource' ...
    my @despres = llista_ids_despres();

    my $id = 4;

    return $id;
}

sub consulta_recurs {
    my $response = GET '/resource';
    warn Dumper($response);
}

sub modifica_recurs { }

sub esborra_recurs { }

sub parse_resource_ids {
    my ($json) = @_;
    my @result;
    for my $r ( decode_json($json) ) {
        push @result, $r{'id'};
    }
}
