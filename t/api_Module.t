#!perl

use strict;
use warnings;
use utf8::all;
use Test::More;
use JSON;

use lib 't/lib';
use HTTP::Request::Common::Bug65843 qw( GET POST PUT DELETE );

BEGIN {
    require 't/TestingDB.pl';
    use_ok 'Catalyst::Test' => 'V2::Server';
}

my $ID = '';

my @tests = @{ require 'doc/api/Resource.pl' };

# @id: variable amb tots els identificadors dels recursos existents al server
my @id;

for my $t (@tests) {
    test_smeagol_resource($t);
}

done_testing();

sub test_smeagol_resource {
    my ($t) = @_;

    my ( $nr, $desc, $call, $op,$input, $status, $headers, $output ) =
		 ($t->{num},$t->{desc},$t->{call},$t->{op},$t->{input},$t->{output}->{status},$t->{output}->{headers}{Location},$t->{output}{data});

	my $uri;
	($op eq 'POST')? ($uri = $t->{uri}) : ($uri = $t->{uri}->());

	if(($op eq 'DELETE') && ($status eq '200 OK') ){
		     pop(@id);
	}	

	if( ($op eq 'GET') && ($uri =~ /\d+/) ){
		$output =~ s/}/,"id":"$ID"}/;
	}

	#Cal incloure els ids a l'output	
	if( ($op eq 'GET') && ($uri eq '/resource') ){
		    my $i = 0;
		    
		    my @output_ = split /,\s+/,$output;
		    
		    foreach (@id){
		        $output_[$i] =~ s/}/,"id":"$id[$i]"}/;
		        $i++;  
		    }
	
		    $output = join(", ",@output_);
	}

   
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
		my $id = $r->headers->as_string();
		$id =~ /.*Location:.*\/resource\/(\d+)+/;
		$ID = $1;
		
		if(($op eq 'POST') && ($status eq '201 Created') ){    
		    push(@id, $ID);
	    }
    };
	is_deeply (decode_json($r->decoded_content()), decode_json($output), "$prefix.output" );
}

sub generated_uri_resource {
    return qq{/resource/$ID};
}
sub uri_resource {
    return qq{/resource};
}
