#!perl

use strict;
use warnings;
use utf8::all;
use Data::Dumper;

use Test::More;

use lib 't/lib';
use HTTP::Request::Common::Bug65843 qw( GET POST PUT DELETE );

BEGIN {
    require 't/TestingDB.pl';
    use_ok 'Catalyst::Test' => 'V2::Server';
}

my @tests = (
    {    # Crear un nou event
		num		=> 1,
		desc	=> 'Crea un nou event',
		call	=> 'TestCreateEvent',
        op      => 'POST',
        uri     => '/event',
        input => {
            info		=> 'INFORMATION',
			description => 'DESCRIPTION',
			starts		=> '2011-02-16T04:00:00',
			ends		=> '2011-02-16T05:00:00',
        },
        output => {
            status  => '201 Created',
            headers => { Location => qr{/event/\d+} },
            data 	=> '[]',
        },
    },
);

for my $t (@tests) {
    test_smeagol_event($t);
}

sub test_smeagol_event {
    my ($t) = @_;

    my ( $nr, $desc, $call, $op, $uri, $input, $status, $headers, $output ) =
		 ($t->{num},$t->{desc},$t->{call},$t->{op},$t->{uri},$t->{input},$t->{output}->{status},$t->{output}->{headers},$t->{output}{data});

    my $prefix = "Test[$nr]: $call";
    my $req = do { no strict 'refs'; \&$op };
    my $r = request(
        $req->( $uri, Accept => 'application/json', Content => $input )
    );

    is ( $r->code().' '.$r->message(), $status, "$prefix.status" );

    SKIP: {
        skip "$prefix.headers", 1
            unless defined $headers && $headers ne '';

        like( $r->headers->as_string(), qr/$headers/, "$prefix.headers" );
    };

    is  ( $r->decoded_content(), $output, "$prefix.output" );
}
