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
								dtent		=> '2012-03-12T14:00:00',
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
					status => 201
				},

			);

foreach my $obj (@objs){
	my ($uri, $op, $input, $status) = ($obj->{uri}, $obj->{op}, $obj->{input}, $obj->{status});

	my $req = do { no strict 'refs'; \&$op };	
	my $r = request(
	        $req->( $uri, Accept => 'application/json', Content => $input )
	    );
	#my $id = $r->headers->as_string();
	#$id =~ /.*Location:.*\/resource\/(\d)+/;
	
	is($r->code(),$status, "objecte creat a $uri" );
}



done_testing();
