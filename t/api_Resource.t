#!perl

use strict;
use warnings;
use utf8::all;

use Test::More;
use HTTP::Request::Common qw( GET POST PUT DELETE );
use HTTP::Status qw(:constants :is status_message);
use Data::Dumper::Simple;
use JSON;
use List::Compare;

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

my $RESOURCE_ID_GLOBAL;

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
            headers => { Location => qr{/resource/$RESOURCE_ID_GLOBAL} },
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
    
    is( $result->code, $test->{sortida}{status}, 'response status' );
    
    if ($result->header('Location')) {
        like(
            $result->header('Location'),
            $test->{'sortida'}{'headers'}{'Location'},
            "resource location header"
        );
    }
}

sub llista_ids {
    my $rp = request( GET('/resource') );

    return parse_resource_ids( $rp->content );
}

sub crea_recurs {
    my ($entrada) = @_;

    my @abans = llista_ids();

    my $rp = request( POST '/resource', $entrada );

    my @despres = llista_ids();

    my $lc = List::Compare->new( \@abans, \@despres );
    my @ids = $lc->get_complement;

    fail("obtenir l'identificador del resource acabat de crear")
        if @ids == 0;

    $RESOURCE_ID_GLOBAL = $ids[0];
    
    return $rp;
}

sub consulta_recurs { }

sub modifica_recurs { }

sub esborra_recurs { }

#
# extracts the ids from a resource list, given the JSON representation of the list
#
sub parse_resource_ids {
    my ($json) = @_;

    return map { $_->{id}; } @{ decode_json($json) };
}
