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
#   title   => 'SomeTest',
#   op      => operador ('GET', 'POST', 'PUT', 'DELETE'),
#   uri     => la url (p.ex. /resource/NN),
#   input => [ nom_parametre1 => val, nom_param2 => val2, ... ],
#   output => {
#                 status => HTTP status code + message (p.ex. '201 Created'),
#                 headers => { header1 => val1, ... },
#                 body => json string
#              },
# }

my @tests = (
    {   title => 'CreaRecurs',
        op    => 'POST',
        uri   => sub {'/resource'},
        input => {
            description => 'aula',
            info        => 'resource info',
        },
        output => {
            status  => HTTP_CREATED . ' ' . status_message(HTTP_CREATED),
            headers => { Location => \&generated_resource_id },
        },
    },

    {   title  => 'ConsultaRecurs',
        op     => 'GET',
        uri    => \&generated_uri,
        input  => {},
        output => {
            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
            headers => {},
            body    => { description => 'aula', info => 'resource info' }
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
        title => $test->{'title'},
        uri   => $test->{'uri'}->(),
        input => $test->{'input'}
    };

    my $result = $sub->(%$args);

    like( generated_uri(), qr{/resource/\d+},
        $test->{'title'} . ": id ben format" );

    is( $result->code . ' ' . $result->message,
        $test->{'output'}{'status'},
        $test->{'title'} . ': response status'
    );

    if ( $result->header('Location') ) {
        like(
            $result->header('Location'),
            $test->{'output'}{'headers'}{'Location'}->(),
            $test->{'title'} . ': resource location header'
        );
    }

    if ( exists $test->{'output'}{'body'} ) {
        $test->{'output'}{'body'}{'id'} = $GENERATED_RESOURCE_ID;
        is_deeply(
            decode_json( $result->content ),
            $test->{'output'}{'body'},
            $test->{'title'} . ': response content'
        );
    }
}

sub llista_ids {
    my $rp = request( GET('/resource') );

    return parse_resource_ids( $rp->content );
}

sub crea_recurs {
    my %arg = @_;

    my ( $title, $uri, $input )
        = ( $arg{'title'}, $arg{'uri'}, $arg{'input'} );

    my @abans = llista_ids();

    my $rp = request( POST '/resource', $input );

    my @despres = llista_ids();

    my $lc = List::Compare->new( \@abans, \@despres );
    my @ids = $lc->get_complement;

    ok( @ids > 0,
        $title . ": obtenir l'identificador del resource acabat de crear" );

    $GENERATED_RESOURCE_ID = $ids[0];

    return $rp;
}

sub consulta_recurs {
    my %args = @_;
    my $uri  = $args{'uri'};

    my $rp = request( GET $uri);
    return $rp;
}

sub modifica_recurs { }

sub esborra_recurs { }

#
# extracts the ids from a resource list, given the JSON representation of the list
#
sub parse_resource_ids {
    my ($json) = @_;

    return map { $_->{id}; } @{ decode_json($json) };
}
