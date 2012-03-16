#!perl

use strict;
use warnings;
use utf8::all;
use Test::More;
use JSON;

use lib 't/lib';
use HTTP::Request::Common::Bug65843 qw( GET POST PUT DELETE );
use LWP::UserAgent;
use Data::Dumper;

BEGIN {
    require 't/TestingDB.pl';
    use_ok 'Catalyst::Test' => 'V2::Server';
}

my %ops = ( 'GET' => 'consulta', 'POST' => 'crea', 'PUT' => 'actualitza', 'DELETE' => 'esborra' );

my @objs = 	(
				{
					uri => '/resource',
					op => 'POST',
					input => {
								info=>'RESOURCE 1 INFORMATION',
								description => 'DESCRIPTION',
							},
					output => '[]',
					status => 201,
				},
				{
					uri => '/event',
					op => 'POST',
					input => {
								info		=> 'EVENT 1 INFORMATION',
			    		        description	=> 'DESCRIPTION',
			    		        starts		=> '2011-02-16T04:00:00',
	    				        ends		=> '2011-02-16T05:00:00',
				   			},
					output => '[]',
					status => 201,
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 1 INFORMATION',
								id_resource	=> 1,
								id_event	=> 1,
								dtstart		=> '2012-03-12T09:00:00',
								dtend		=> '2012-03-12T14:00:00',
#								duration	=> ,
								frequency	=> 'daily',
#								interval	=> ,
								until		=> '2012-03-16T14:00:00',
#								by_minute	=> '',
#								by_hour		=> '',
#								by_day		=> '',
#								by_month	=> '',
#			    		        by_day_month=> '',
#	    				        exception	=> '',
				   			},
					output => '[]',
					status => 201,
				},
				{
					uri => '/booking/1',
					op => 'GET',
					input => '',
					output => '{
						"id":"1",
						"info":"BOOKING 1 INFORMATION",
						"id_resource":"1",
						"id_event":"1",
						"dtstart":"2012-03-12T09:00:00",
						"dtend":"2012-03-12T14:00:00",
						"frequency":"daily",
						"until":"2012-03-16T14:00:00",
						"duration":"300",
						"by_minute":"0",
						"by_hour":"9",
						"interval":"1"
					}',
					status => 200,
				},

			);

foreach my $obj (@objs){
	my ($uri, $op, $input, $status, $output) = ($obj->{uri}, $obj->{op}, $obj->{input}, $obj->{status},$obj->{output});

	my $req = do { no strict 'refs'; \&$op };	
	my $r = request(
	        $req->( $uri, Accept => 'application/json', Content => $input )
	    );
	my $id = $r->headers->as_string();
	$id =~ /.*Location:.*\/resource\/(\d)+/;
	$id=$1;

	is($r->code(),$status, "$ops{$op} objecte a $uri" );
	is_deeply (decode_json($r->decoded_content()), decode_json($output), "output correcte per $op $uri" );
=pod	
    SKIP: {
        skip "$prefix.headers", 1
            unless defined $headers && $headers ne '';

        like( $r->headers->as_string(), qr/$headers/, "$prefix.headers" );
		my $id = $r->headers->as_string();
		$id =~ /.*Location:.*\/resource\/(\d)+/;
		$ID = $1;

		if(($op eq 'POST') && ($status eq '201 Created') ){    
		    push(@id, $ID);
	    }
    };
=cut


}



done_testing();
