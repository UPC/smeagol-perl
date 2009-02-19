#!/usr/bin/perl

use Test::More tests => 12;

use strict;
use warnings;
use Data::Dumper;

BEGIN {
	unlink glob "/tmp/smeagol_datastore/*";
    use_ok($_) for qw(Server Client);
}

my $server_port = 8000;
my $server      = "http://localhost:$server_port";
my $pid = Server->new($server_port)->background();

my $client = Client->new();
ok(!defined $client ,'client not created');

$client = Client->new($server);
ok(ref $client eq 'Client' ,'client created');



my @idResources = $client->listResources();
ok(@idResources == 0, 'list resources empty');

my $idRes1 = $client->createResource("aula","hora");
ok($idRes1 eq "/resource/1", 'created resource 1');

@idResources = $client->listResources();
ok($idResources[0] eq "/resource/1",'resource 1 at list');

$idRes1 = $client->updateResource("/resource/1","aulaaaaaa","hora");
ok($idRes1 eq "/resource/1", 'updated resource 1');

my $dataRes1 = $client->getResource($idRes1);
ok(
	$dataRes1->{granularity} eq 'hora' &&
	$dataRes1->{description} eq 'aulaaaaaa' &&
	!defined $dataRes1->{agenda}
	,'get resource 1');

@idResources = $client->listResources();
ok($idResources[0] eq "/resource/1",'resource 1 at list');

$idRes1 = $client->delResource("/resource/1");
ok($idRes1 eq "/resource/1", 'deleted resource 1');

@idResources = $client->listResources();
ok(@idResources == 0 ,'list resources empty');

=pod

my $idRes2 = $client->createResource("projector","minuts");
ok($idRes2 eq "/resource/2", 'created resource 2');

@idResources = $client->listResources();
ok(@idResources == 1,'list resources 1 element');
ok($idResources[0] eq "/resource/2",'resource 2 at begin');

my $idRes3 = $client->createResource("projector","dia");
ok($idRes3 eq "/resource/3", 'created resource 3');

@idResources = $client->listResources();
ok(@idResources == 2, 'list resources 2 elements');
ok($idResources[0] eq "/resource/2", 'resource 2 at begin');
ok($idResources[1] eq "/resource/3", 'resource 3 at end');

my $idAgenda = $client->createAgenda($idResources[0]);
ok($idAgenda eq $idResources[0], 'agenda created at '.$idResources[0]);

my @idBookings = $client->getAgenda($idAgenda);
ok(@idBookings == 0, 'list bookings empty');

my $Agenda = $client->updateAgenda($idAgenda);
ok($Agenda eq $idAgenda, 'agenda $idAgenda updated');

$idAgenda = $client->delAgenda($idResources[0]);
ok($idAgenda eq $idResources[0], 'agenda deleted at '.$idResources[0]);

$idAgenda = $client->createAgenda($idResources[1]);
ok($idAgenda eq $idResources[1], 'agenda created at '.$idResources[0]);

my @from = (2008, 4, 14, 17, 0, 0 );
my @to = (2008, 4, 14, 19, 0 , 0 );
my $idBook1 = $client->createBooking($idAgenda,@from,@to);
ok($idBook1 eq $idAgenda."/booking/1",'booking 1 created');

@idBookings = $client->getAgenda($idAngenda);
ok(@idBookings == 1, "booking 1 at agenda's list");
ok($idBookings[0] eq $idBook1, 'booking 1 at begin');

my $Book = $client->getBooking($idBook1);
ok(
	$Book->{from}->{year} == 2008 &&
	$Book->{from}->{month} == 4 &&
	$Book->{from}->{day} == 14 &&
	$Book->{from}->{hour} == 17 &&
	$Book->{to}->{year} == 2008 &&
	$Book->{to}->{month} == 4 &&
	$Book->{to}->{day} == 14 &&
	$Book->{to}->{hour} == 19 ,
	'get booking 1'
);

my $idBook = $client->updateBooking($idBook1);
ok($idBook == $idBook1, 'updated booking 1');

$idBook = $client->delBooking($idBook1);
ok($idBook == $idBook1, 'updated booking 1');

@idBookings = $client->getAgenda($idAngenda);
ok(@idBookings == 0, "agenda's list empty");

=cut

END {
	kill 3, $pid;
}
