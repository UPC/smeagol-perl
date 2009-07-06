#!/usr/bin/perl

use Test::More tests => 22;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(
        DateTime
        DateTime::Span
        DateTime::Set
        DateTime::SpanSet
		DateTime::Event::ICal
    );
}

my ($start, $end, $span, $set, $duration, $spanSet , @localtime);

#cada agost
{
	$start	= DateTime->from_epoch( epoch=> 0 );
	$set = DateTime::Event::ICal->recur( 
      		dtstart => $start,
      		freq =>    'yearly',
			bymonth => [ 8 ],
 	);
	
	my $spanSet = DateTime::SpanSet->from_set_and_duration(
	        set      => $set,
		months => 1,
	);

	#while (my $dt = $spanSet->next ) {
        	#print $dt->min->ymd." ".$dt->min->hms." ";   # first date of span
       		#print $dt->max->ymd." ".$dt->max->hms." \n";   # last date of span
   	#}

	my $d31_7 = DateTime->new( year => 2009, month => 7, day => 31);
	ok(!$spanSet->contains($d31_7), 'no conte el dia 31 del 7 del 2009');

	my $d1_8 = DateTime->new( year => 2009, month => 8, day => 01);
	ok($spanSet->contains($d1_8), 'conte el dia 1 del 8 del 2009');

	my $d31_8 = DateTime->new( year => 2009, month => 8, day => 31);
	ok($spanSet->contains($d31_8), 'conte el dia 31 del 8 del 2009');

	my $d1_9 = DateTime->new( year => 2009, month => 9, day => 1);
	ok(!$spanSet->contains($d1_9), 'no conte el dia 1 del 9 del 2009');

	my $d10_8 = DateTime->new( year => 2009, month => 8, day => 10);
	ok($spanSet->contains($d10_8), 'conte el dia 10 del 8 del 2009');

	my $d10_9 = DateTime->new( year => 2009, month => 9, day => 10);
	ok(!$spanSet->contains($d10_9), 'no conte el dia 10 del 9 del 2009');

	$d1_8 = DateTime->new( year => 1970, month => 8, day => 01);
	ok($spanSet->contains($d1_8), 'conte el dia 1 del 8 del 1970');

	$d31_8 = DateTime->new( year => 1970, month => 8, day => 31);
	ok($spanSet->contains($d31_8), 'conte el dia 31 del 8 del 1970');

	$d1_9 = DateTime->new( year => 1970, month => 9, day => 1);
	ok(!$spanSet->contains($d1_9), 'no conte el dia 1 del 9 del 1970');

	$d10_8 = DateTime->new( year => 1970, month => 8, day => 10);
	ok($spanSet->contains($d10_8), 'conte el dia 10 del 8 del 1970');

	$d10_9 = DateTime->new( year => 1970, month => 9, day => 10);
	ok(!$spanSet->contains($d10_9), 'no conte el dia 10 del 9 del 1970');

}

#cada 11 de setembre
{
	$start	= DateTime->from_epoch( epoch=> 0 );
	$set = DateTime::Event::ICal->recur( 
      		dtstart => $start,
      		freq =>    'yearly',
			bymonth => [ 9 ],
			bymonthday => [11]
 	);
	
	my $spanSet = DateTime::SpanSet->from_set_and_duration(
	        set      => $set,
			days => 1,
	);

	#while (my $dt = $spanSet->next ) {
        	#print $dt->min->ymd." ".$dt->min->hms." ";   # first date of span
       		#print $dt->max->ymd." ".$dt->max->hms." \n";   # last date of span
   	#}

	my $d10_9 = DateTime->new( year => 2009, month => 9, day => 10);
	ok(!$spanSet->contains($d10_9), 'no conte el dia 10 del 9 del 2009');

	my $d11_9 = DateTime->new( year => 2009, month => 9, day => 11);
	ok($spanSet->contains($d11_9), 'conte el dia 11 del 9 del 2009');

	my $d12_9 = DateTime->new( year => 2009, month => 9, day => 12);
	ok(!$spanSet->contains($d12_9), 'no conte el dia 12 del 9 del 2009');

	$d10_9 = DateTime->new( year => 1970, month => 9, day => 10);
	ok(!$spanSet->contains($d10_9), 'no conte el dia 10 del 9 del 1970');

	$d11_9 = DateTime->new( year => 1970, month => 9, day => 11);
	ok($spanSet->contains($d11_9), 'conte el dia 11 del 9 del 1970');

	$d12_9 = DateTime->new( year => 1970, month => 9, day => 12);
	ok(!$spanSet->contains($d12_9), 'no conte el dia 12 del 9 del 1970');

}
