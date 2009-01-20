#!/usr/bin/perl

use Test::More tests => 12;

use strict;
use warnings;
use Data::Dumper;

BEGIN { use_ok("Client") }

eval { Client::_client_call( "localhost", "/", 80, "FAIL" ); };

ok( $@ =~ /Invalid Command/ );

#Llista de recursos buida
my @res_list_resources =  Client->list_resources();
ok($res_list_resources[0] =~ /200 OK/ , 'list_resources empty');

#Creant recurs
my @res_r1 = Client->create_resource("aula 2","hores");
ok($res_r1[0] =~ /201/ ,'created resource');

my @res_r2 = Client->create_resource("altra aulaaa","dies");
ok($res_r2[0] =~ /201/ ,'created resource');

#Recuperant recurs
my @ret_r50 = Client->retrieve_resource(50);
ok($ret_r50[0] =~ /404/ , 'retrieving resource not found');

my @ret_r99 = Client->retrieve_resource(-99);
ok($ret_r99[0] =~ /404/ , 'retrieve_resource not existent');

my @ret_r1 = Client->retrieve_resource(1);
ok($ret_r1[0] =~ /200/ , 'retrieve_resource r1');

my @ret_r2 = Client->retrieve_resource(2);
ok($ret_r2[0] =~ /200/ , 'retrieve_resource r2');

#Esborrant recurs
@ret_r50 = Client->delete_resource(50);
ok($ret_r50[0] =~ /404/ , 'deleting resource not found');

@ret_r50 = Client->delete_resource(1);
ok($ret_r50[0] =~ /200/ , 'deleting resource found');

@res_list_resources =  Client->list_resources();
ok($res_list_resources[0] =~ /200 OK/ , 'list_resources not empty');

#Actualitzant recurs
=pod
my $ret_r2 = Client->update_resource(2,"portatil","mesos");
ok($ret_r2 =~ /portatil/ , 'update_resource r2');

my @books_r2 = Client->list_bookings_resource(2);
ok($book_r2[0] =~ //, 'list_bookings_resource empty');
=cut
