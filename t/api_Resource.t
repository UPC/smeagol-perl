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
    return
        defined $GENERATED_RESOURCE_ID
        ? qq{/resource/$GENERATED_RESOURCE_ID}
        : qq{/resource/};
}

#
# TESTS FORMAT DESCRIPTION
#
# Every test is defined by the following structure. Note that
# several fields ('body', for instance) are optional in some tests.
#
# Note that response header values are references to routines returning regexes.
#
# {
#   titol   => 'SomeTestTitle',
#   op      => HTTP method name (ex: 'GET', 'POST', 'PUT', 'DELETE'),
#   uri     => reference to some routine which builds the request url (ex: \&generated_uri),
#   entrada => { param1 => val1, param2 => val2, ... },
#   sortida => {
#                 status => HTTP status code + message (ex: '201 Created'),
#                 headers => { header1 => sub { qr{regex1} }, ... },
#                 body => a (possibly empty) valid json string
#              },
# }

# slurp resource test collection
my @tests = @{ require 'doc/api/test_Resource.pl' };

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
        $test->{titol} . ": id ben format" )
        if defined $GENERATED_RESOURCE_ID;

    is( $result->code . ' ' . $result->message,
        $test->{sortida}{status},
        $test->{titol} . ': response status'
    );

    foreach ( keys %{ $test->{sortida}{headers} } ) {
        if ( $result->header($_) ) {
            like(
                $result->header($_),
                $test->{sortida}{headers}{$_}->(),
                $test->{titol} . ": '$_' header does not match"
            );
        }
        else {
            fail( $test->{titol} . ": '$_' header should be returned" );
        }
    }

    if (   exists $test->{sortida}{body}
        && defined $test->{sortida}{body}
        && $test->{sortida}{body} ne '' )
    {
        $test->{sortida}{body}{id} = $GENERATED_RESOURCE_ID
            if defined $GENERATED_RESOURCE_ID;
        my $got = decode_json( $result->content );
        is_deeply( $got, $test->{sortida}{body},
                  $test->{titol}
                . ': response content '
                . Dumper($got)
                . ' expected: '
                . Dumper( $test->{sortida}{body} ) );
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

    $GENERATED_RESOURCE_ID = $ids[0] if @ids;

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
