#!perl

use strict;
use warnings;
use utf8::all;

use Test::More;
use HTTP::Request::Common::Bug65843 qw( GET POST PUT DELETE );
use HTTP::Status qw(:constants :is status_message);
use Data::Dumper::Simple;
use JSON;
use List::Compare;

BEGIN {
    require 't/TestingDB.pl';
    use_ok 'Catalyst::Test' => 'V2::Server';
}

# global variable to store server-generated IDs
my $GENERATED_RESOURCE_ID;

# returns regex to be used in 'well-formedness' tests
sub generated_resource_id {
    my $uri = generated_uri();

    # \Q and \E to avoid meta chars in regex
    return qr{\Q$uri\E};
}

sub generated_uri {
    return qq{/resource/$GENERATED_RESOURCE_ID};
}

# Every test is defined by the following structure. Note that
# several fields ('body', for instance) are optional in some tests.
#
# {
#   titol   => 'SomeTest',
#   op      => operador ('GET', 'POST', 'PUT', 'DELETE'),
#   uri     => la url (p.ex. /resource/NN),
#   entrada => [ nom_parametre1 => val, nom_param2 => val2, ... ],
#   sortida => {
#                 status => HTTP status code + message (p.ex. '201 Created'),
#                 headers => { header1 => val1, ... },
#                 body => json string
#              },
# }

my @tests = (
    {   titol   => 'CreaRecurs',
        op      => 'POST',
        uri     => sub {'/resource'},
        entrada => {
            description => 'aula',
            info        => 'resource info',
        },
        sortida => {
            status  => HTTP_CREATED . ' ' . status_message(HTTP_CREATED),
            headers => { Location => \&generated_resource_id },
        },
    },

    {   titol   => 'ConsultaRecurs',
        op      => 'GET',
        uri     => \&generated_uri,
        entrada => {},
        sortida => {
            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
            headers => {},
            body    => { description => 'aula', info => 'resource info' }
        }
    },

    {   titol   => 'ModificaRecurs',
        op      => 'PUT',
        uri     => \&generated_uri,
        entrada => {
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        },
        sortida => {
            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
            headers => {},
        }
    }
);

my %helpers = (
    GET    => \&consulta_recurs,
    POST   => \&crea_recurs,
    PUT    => \&modifica_recurs,
    DELETE => \&esborra_recurs,
);

for my $t (@tests) {
    test_smeagol_resource($t);
}

done_testing();

sub test_smeagol_resource {
    my ($test) = @_;
    my $sub    = $helpers{ $test->{'op'} };
    my $args   = {
        titol   => $test->{'titol'},
        uri     => $test->{'uri'}->(),
        entrada => $test->{'entrada'}
    };

    my $result = $sub->(%$args);

    like( generated_uri(), qr{/resource/\d+},
        $test->{titol} . ": id ben format" );

    is( $result->code . ' ' . $result->message,
        $test->{sortida}{status},
        $test->{titol} . ': response status'
    );

    if ( defined $result->header('Location') ) {
        like(
            $result->header('Location'),
            $test->{sortida}{headers}{Location}->(),
            $test->{titol} . ': "Location" header'
        );
    }

    if ( exists $test->{sortida}{body} && $test->{sortida}{body} ne '' ) {
        $test->{sortida}{body}{id} = $GENERATED_RESOURCE_ID;
        is_deeply(
            decode_json( $result->content ),
            $test->{sortida}{body},
            $test->{titol} . ': response content'
        );
    }
}

sub llista_ids {
    my $rp = request( GET '/resource' );

    return parse_resource_ids( $rp->content );
}

sub crea_recurs {
    my %arg = @_;

    my ( $titol, $uri, $entrada ) = ( $arg{titol}, $arg{uri}, $arg{entrada} );

    my @abans = llista_ids();

    my $rp = request( POST '/resource', $entrada );

    my @despres = llista_ids();

    my $lc = List::Compare->new( \@abans, \@despres );
    my @ids = $lc->get_complement;

    ok( @ids > 0,
        $titol . ": obtenir l'identificador del resource acabat de crear" );

    $GENERATED_RESOURCE_ID = $ids[0];

    return $rp;
}

sub consulta_recurs {
    my %args = @_;
    my $uri  = $args{uri};

    my $rp = request( GET $uri);
    return $rp;
}

sub modifica_recurs {
    my %args = @_;
    my $uri  = $args{uri};

    my $rp = request( PUT $uri );
    return $rp;
}

sub esborra_recurs { }

#
# extracts the ids from a resource list, given the JSON representation of the list
#
sub parse_resource_ids {
    my ($json) = @_;

    return map { $_->{id}; } @{ decode_json($json) };
}
