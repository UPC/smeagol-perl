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

=pod
my ( $uri, $op, $input, $status ) = ('/resource','GET', "{info=>'RESOURCE 1 INFORMATION',description => 'DESCRIPTION'}", 200);
my $req = do { no strict 'refs'; \&$op };	
my $r = request(
        $req->( $uri, Accept => 'application/json', Content => $input )
    );
#my $id = $r->headers->as_string();
#$id =~ /.*Location:.*\/resource\/(\d)+/;

is($r->code(),$status, "objecte creat a $uri" );

=cut
my @objs = 	(
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
#								duration	=> ,
								frequency	=> 'daily',
								interval	=> 1,
								until		=> '2012-03-16T14:00:00',
								by_minute	=> '1',
								by_hour		=> '1',
#								by_day		=> '',
#								by_month	=> '',
#			    		        by_day_month=> '',
#	    				        exception	=> '',
				   			},
					output => '[]',
					status => 201
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
								info		=> 'BOOKING 1 INFORMATION',
								id_resource	=> 2,
								id_event	=> 2,
								dtstart		=> '2012-03-13T09:00:00',
								dtend		=> '2012-03-13T14:00:00',
								#duration	=> 60,
								frequency	=> 'weekly',
								interval	=> 1,
								until		=> '2012-03-15T14:00:00',
								by_minute	=> '2',
								by_hour		=> '2',
								by_day		=> 'we',
								#by_month	=> '-2',
								#by_day_month	=> '-2',
#	    				        exception	=> '',
				   			},
					output => '[]',
					status => 201
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
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 3 INFORMATION',
								id_resource	=> 3,
								id_event	=> 3,
								dtstart		=> '2012-03-18T09:00:00',
								dtend		=> '2012-04-18T14:00:00',
								#duration	=> ,
								frequency	=> 'monthly',
								interval	=> 1,
								until		=> '2012-04-18T14:00:00',
								by_minute	=> '1',
								by_hour		=> '14',
								#by_day		=> '1FR',
								#by_month	=> '-3',
	        			    		        by_day_month	=> '1',
			    				        #exception	=> '',
				   			},
					output => '[]',
					status => 201
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
					uri => '/booking',
					op => 'POST',
					input => {
								info		=> 'BOOKING 3 INFORMATION',
								id_resource	=> 4,
								id_event	=> 4,
								dtstart		=> '2012-03-19T09:00:00',
								dtend		=> '2015-04-19T14:00:00',
								#duration	=> 60,
								frequency	=> 'yearly',
								interval	=> 1,
								until		=> '2015-04-19T14:00:00',
								by_minute	=> '1',
								by_hour		=> '1',
								#by_day		=> '1mo',
								by_month	=> '-3',
	        			    		        by_day_month	=> '15',
			    				        #exception	=> '',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/1',
					op => 'DELETE',
					input => '',
					output => '[]',
					status => 200
				},
				{
					uri => '/booking/2',
					op => 'DELETE',
					input => '',
					output => '[]',
					status => 200
				},
				{
					uri => '/booking/3',
					op => 'DELETE',
					input => '',
					output => '[]',
					status => 200
				},
				{
					uri => '/booking/4',
					op => 'DELETE',
					input => '',
					output => '[]',
					status => 200
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
								interval	=> 1,
								until		=> '2012-03-16T14:00:00',
								by_minute	=> '1',
								by_hour		=> '1',
#								by_day		=> '',
#								by_month	=> '',
#			    		        by_day_month=> '',
#	    				        exception	=> '',
				   			},
					output => '[]',
					status => 201
				},
				{
					uri => '/booking/1',
					op => 'DELETE',
					input => '',
					output => '[]',
					status => 404
				},
				{
					uri => '/booking/5',
					op => 'DELETE',
					input => '',
					output => '[]',
					status => 200
				},
				{
					uri => '/booking',
					op => 'GET',
					input => '',
					output => '[]',
					status => 200
				},

			);

foreach my $obj (@objs){
	my ($uri, $op, $input, $status, $output) = ($obj->{uri}, $obj->{op}, $obj->{input}, $obj->{status},$obj->{output});

	my $req = do { no strict 'refs'; \&$op };	
	my $r = request(
	        $req->( $uri, Accept => 'application/json', Content => $input )
	    );
	my $id = $r->headers->as_string();
	$id =~ /.*Location:.*\/event\/(\d)+/ if ($uri =~ 'event');
	$id =~ /.*Location:.*\/resource\/(\d)+/ if ($uri =~ 'resource');
	$id = $1;
	is($r->content(),$output, "contingut $output a $uri" );
	is($r->code(),$status, "objecte creat a $uri" );
}



done_testing();
