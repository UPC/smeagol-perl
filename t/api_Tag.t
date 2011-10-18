#!perl

use strict;
use warnings;
use utf8::all;

use Test::More;
use Text::CSV;
use HTTP::Request::Common qw( GET POST PUT DELETE );

BEGIN {
    require 't/TestingDB.pl';
    use_ok 'Catalyst::Test' => 'V2::Server';
}

my $tag_csv = 'doc/api/Tag.csv';

# set binary to accept non-ASCII chars
my $csv = Text::CSV->new({ binary => 1 })
    or die "Cannot use CSV: ".Text::CSV->error_diag ();
                 
open my $fh, '<', $tag_csv
    or die "Cannot open $tag_csv: $!";

my $titles = $csv->getline( $fh );
$csv->column_names(@$titles);

while ( my $row = $csv->getline( $fh ) ) {
    test_smeagol_tag($row);
}

$csv->eof or $csv->error_diag();
close $fh;

done_testing();


sub test_smeagol_tag {
    my ($row) = @_;

    my ( $nr, $desc, $call, $op, $uri, $input, $status, $headers, $output ) = @$row;

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