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

my @objs = 	(		{
					uri => '/booking/1',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/resource',
					op => 'POST',
					input => {
								info=>'RESOURCE 1 INFORMATION',
								description => 'DESCRIPTION',
							},
					output => '[]',
					status => 201
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
					status => 201
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
								duration	=>undef,
								frequency	=> 'daily',
								interval	=>undef,
								until		=>undef,
								by_minute	=> undef,
								by_hour		=> undef,
								by_day		=> undef,
								by_month	=> undef,
								by_day_month	=> undef,
				   			},
					output => '[]',
					status => 201
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
								"duration":"300",
								"until":"2012-03-12T14:00:00",
								"frequency":"daily",
								"interval":"1",
								"by_minute":"0",
								"by_hour":"9",
								"by_day": null,
								"by_month":  null,
								"by_day_month": null
				   			}',
					status => 200
				},
				{
					uri => '/booking/2',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 2 INFORMATION',
								id_resource	=> 1,
								id_event	=> 1,
								dtstart		=> '2012-03-12T14:00:00',
								dtend		=> '2012-03-12T16:00:00',
								duration	=>undef,
								frequency	=>'daily',
								interval	=>undef,
								until		=>undef,
								by_minute	=> undef,
								by_hour		=> undef,
								by_day		=> undef,
								by_month	=> undef,
								by_day_month	=> undef,
	    				        		
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/2',
					op => 'GET',
					input => '',
					output => '{
								"id":"2",
								"info":"BOOKING 2 INFORMATION",
								"id_resource":"1",
								"id_event":"1",
								"dtstart":"2012-03-12T14:00:00",
								"dtend":"2012-03-12T16:00:00",
								"duration":"120",
								"until":"2012-03-12T16:00:00",
								"frequency":"daily",
								"interval":"1",
								"by_minute":"0",
								"by_hour":"14",
								"by_day": null,
								"by_month": null,
								"by_day_month": null
				   			}',
					status => 200
				},
				{
					uri => '/booking/3',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/resource',
					op => 'POST',
					input => {
								info=>'RESOURCE 2 INFORMATION',
								description => 'DESCRIPTION2',
							},
					output => '[]',
					status => 201
				},
				{
					uri => '/event',
					op => 'POST',
					input => {
								info		=> 'EVENT 2 INFORMATION',
			    		        description	=> 'DESCRIPTION2',
			    		        starts		=> '2011-02-15T04:00:00',
	    				        ends		=> '2011-02-15T05:00:00',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 3 INFORMATION',
								id_resource	=> 2,
								id_event	=> 2,
								dtstart		=> '2012-03-13T09:00:00',
								dtend		=> '2012-03-13T14:00:00',
								duration	=>undef,
								frequency	=> 'weekly',
								until		=> '2012-03-16T14:00:00',
								by_minute	=> undef,
								by_hour		=> undef,
								by_day		=> 'we,fr',
								by_month	=> undef,
								by_day_month	=> undef,
			    				        exception	=> undef,
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/3',
					op => 'GET',
					input => '',
					output => '{
								"id":"3",
								"info":"BOOKING 3 INFORMATION",
								"id_resource":"2",
								"id_event":"2",
								"dtstart":"2012-03-13T09:00:00",
								"dtend":"2012-03-13T14:00:00",
								"duration":"300",
								"until":"2012-03-16T14:00:00",
								"frequency":"weekly",
								"interval":"1",
								"until":"2012-03-16T14:00:00",
								"by_minute":"0",
								"by_hour":"9",
								"by_day":"we,fr",
								"by_month": null,
								"by_day_month": null
							}',
					status => 200
				},
				{
					uri => '/booking/4',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info            => 'BOOKING 4 INFORMATION',
								id_resource     => 2,
								id_event        => 2,
								dtstart         => '2012-03-13T09:00:00',
								dtend           => '2012-03-13T14:00:00',
								duration	=> undef,
								frequency       => 'weekly',
								by_minute	=> undef,
								by_hour		=> undef,
								until           => '2012-03-16T14:00:00',
								by_day          => 'tu,th',
								by_month	=> undef,
								by_day_month	=> undef,
			    				        exception	=> undef,
							},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/4',
					op => 'GET',
					input => '',
					output => '{
								"id":"4",
								"info":"BOOKING 4 INFORMATION",
								"id_resource":"2",
								"id_event":"2",
								"dtstart":"2012-03-13T09:00:00",
								"dtend":"2012-03-13T14:00:00",
								"duration":"300",
								"until":"2012-03-16T14:00:00",
								"frequency":"weekly",
								"interval":"1",
								"until":"2012-03-16T14:00:00",
								"by_minute":"0",
								"by_hour":"9",
								"by_day":"tu,th",
								"by_month": null,
								"by_day_month": null
							}',
					status => 200
				},
				{
					uri => '/booking/5',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 5 INFORMATION',
								id_resource	=> 2,
								id_event	=> 2,
								dtstart		=> '2012-03-13T14:00:00',
								dtend		=> '2012-03-13T19:00:00',
								duration 	=> undef,
								frequency	=> 'weekly',
								interval	=>undef,
								until		=> '2012-03-16T19:00:00',
								by_minute	=> undef,
								by_hour		=> undef,
								by_day		=> 'we,fr',
								by_month	=> undef,
								by_day_month	=> undef,
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/5',
					op => 'GET',
					input => '',
					output => '{
								"id":"5",
								"info":"BOOKING 5 INFORMATION",
								"id_resource":"2",
								"id_event":"2",
								"dtstart":"2012-03-13T14:00:00",
								"dtend":"2012-03-13T19:00:00",
								"duration":"300",
								"until":"2012-03-16T19:00:00",
								"frequency":"weekly",
								"interval":"1",
								"by_minute":"0",
								"by_hour":"14",
								"until":"2012-03-16T19:00:00",
								"by_day":"we,fr",
								"by_month": null,
								"by_day_month": null
							}',
					status => 200
				},
				{
					uri => '/booking/6',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info            => 'BOOKING 6 INFORMATION',
								id_resource     => 2,
								id_event        => 2,
								dtstart         => '2012-03-13T14:00:00',
								dtend           => '2012-03-13T19:00:00',
								duration 	=>undef,
								frequency       => 'weekly',
								interval	=>undef,
								until           => '2012-03-16T19:00:00',
								by_minute	=> undef,
								by_hour		=> undef,
								by_day          => 'tu,th',
								by_month	=> undef,
								by_day_month	=> undef,
							},
					output => '[]',
                    status => 201
				},
				{
					uri => '/booking/6',
					op => 'GET',
					input => '',
					output => '{
								"id":"6",
								"info":"BOOKING 6 INFORMATION",
								"id_resource":"2",
								"id_event":"2",
								"dtstart":"2012-03-13T14:00:00",
								"dtend":"2012-03-13T19:00:00",
								"until":"2012-03-16T19:00:00",
								"duration":"300",
								"frequency":"weekly",
								"interval":"1",
								"by_minute":"0",
								"by_hour":"14",
								"by_day":"tu,th",
								"by_month": null,
								"by_day_month": null
							}',
					status => 200
				},
				{
					uri => '/resource',
					op => 'POST',
					input => {
								info=>'RESOURCE 3 INFORMATION',
								description => 'DESCRIPTION3',
							},
					output => '[]',
					status => 201
				},
				{
					uri => '/event',
					op => 'POST',
					input => {
								info		=> 'EVENT 3 INFORMATION',
			    		        description	=> 'DESCRIPTION3',
			    		        starts		=> '2011-02-18T04:00:00',
	    				        ends		=> '2011-02-18T05:00:00',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/7',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 7 INFORMATION',
								id_resource	=> 3,
								id_event	=> 3,
								dtstart		=> '2012-03-18T09:00:00',
								dtend		=> '2012-04-18T14:00:00',
								duration 	=> undef,
								frequency	=> 'monthly',
								interval	=> 1,
								until		=> '2012-04-18T14:00:00',
								by_minute	=> '1',
								by_hour		=> '14',
								by_month	=> undef,
								by_month	=> '1',
								by_day_month	=> '1',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/7',
					op => 'GET',
					input => '',
					output => '{
								"id":"7",
								"info":"BOOKING 7 INFORMATION",
								"id_resource":"3",
								"id_event":"3",
								"dtstart":"2012-03-18T09:00:00",
								"dtend":"2012-04-18T14:00:00",
								"duration":"300",
								"until":"2012-04-18T14:00:00",
								"frequency":"monthly",
								"interval":"1",
								"by_minute":"1",
								"by_hour":"14",
								"by_day": null,
								"by_month":"1",
								"by_day_month":"1"
				   			}',
					status => 200
				},
				{
					uri => '/resource',
					op => 'POST',
					input => {
								info=>'RESOURCE 4 INFORMATION',
								description => 'DESCRIPTION4',
							},
					output => '[]',
					status => 201
				},
				{
					uri => '/event',
					op => 'POST',
					input => {
								info		=> 'EVENT 4 INFORMATION',
			    		        description	=> 'DESCRIPTION4',
			    		        starts		=> '2011-02-17T04:00:00',
	    				        ends		=> '2011-02-17T05:00:00',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/8',
					op => 'GET',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 8 INFORMATION',
								id_resource	=> 4,
								id_event	=> 4,
								dtstart		=> '2012-03-19T09:00:00',
								dtend		=> '2015-04-19T14:00:00',
								duration	=> undef,
								frequency	=> 'yearly',
								interval	=> 1,
								until		=> '2015-04-19T14:00:00',
								by_minute	=> undef,
								by_hour		=> undef,
								by_day		=> undef,
								by_month	=> '-3',
								by_day_month	=> '-15',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/8',
					op => 'GET',
					input => '',
					output => '{
								"id":"8",
								"info":"BOOKING 8 INFORMATION",
								"id_resource":"4",
								"id_event":"4",
								"dtstart":"2012-03-19T09:00:00",
								"dtend":"2015-04-19T14:00:00",
								"duration":"300",
								"until":"2015-04-19T14:00:00",
								"frequency":"yearly",
								"interval":"1",
								"by_minute":"0",
								"by_hour":"9",
								"by_day": null,
								"by_month":"-3",
								"by_day_month":"-15"
								
				   			}',
					status => 200
				},

			);

foreach my $obj (@objs){
	my ($uri, $op, $input, $status, $output) = ($obj->{uri}, $obj->{op}, $obj->{input}, $obj->{status}, $obj->{output});

	my $req = do { no strict 'refs'; \&$op };	
	my $r = request(
	        $req->( $uri, Accept => 'application/json', Content => $input )
	    );
	my $id = $r->headers->as_string();
	$id =~ /.*Location:.*\/event\/(\d)+/ if ($uri =~ 'event');
	$id =~ /.*Location:.*\/resource\/(\d)+/ if ($uri =~ 'resource');
	$id = $1;
	is($r->code(),$status, "$ops{$op} objecte a $uri" );
	is_deeply (decode_json($r->decoded_content()), decode_json($output), "output correcte per $op $uri" );
}



done_testing();

