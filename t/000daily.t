#!/usr/bin/perl

use Test::More tests => 17;
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
	DateTime::Event::Recurrence
    );
}

my ($start, $end, $span, $set, $duration, $spanSet );

#de 01-07-09 a 06-07-09, de 8h-10h	 
{
	$start = DateTime->new( year => 2009, month  => 7, day => 1);
	$end = DateTime->new( year => 2009, month => 7, day => 7);

	$set = DateTime::Event::ICal->recur( 
      		dtstart => $start,
      		dtend => $end,
      		freq =>    'daily',
		interval => 1,
      		byhour =>  [ 8 ]
 	);
	
	$duration = DateTime->new( year => 1970, hour => 10, minute => 0 ) - DateTime->new( year => 1970, hour => 8, minute => 0 );
	my $spanSet = DateTime::SpanSet->from_set_and_duration(
	        set      => $set,
	        duration => $duration
	    );

	my $d1_9 	= DateTime->new( year => 2009, month => 07, day => 1 , hour => 9 , minute => 0 );
	my $d1_9_59 = DateTime->new( year => 2009, month => 07, day => 1 , hour => 9 , minute => 59 );
	my $d1_10 	= DateTime->new( year => 2009, month => 07, day => 1 , hour => 10 , minute => 0 );
	my $d4_9 	= DateTime->new( year => 2009, month => 07, day => 4 , hour => 9 , minute => 0 );
	my $d4_7 	= DateTime->new( year => 2009, month => 07, day => 4 , hour => 7 , minute => 0 );
	my $d4_8 	= DateTime->new( year => 2009, month => 07, day => 4 , hour => 8 , minute => 0 );
	my $d4_10 	= DateTime->new( year => 2009, month => 07, day => 4 , hour => 10 , minute => 0 );
	my $d4_9_59 = DateTime->new( year => 2009, month => 07, day => 4 , hour => 9 , minute => 59 );
	my $d7_9_59 = DateTime->new( year => 2009, month => 07, day => 6 , hour => 9 , minute => 59 );
	my $d7_10 	= DateTime->new( year => 2009, month => 07, day => 7 , hour => 10 , minute => 0 );
	my $d8 		= DateTime->new( year => 2009, month => 07, day => 8 , hour => 8 , minute => 0 );

	ok($spanSet->contains($d1_9), 'conte el dia 1 a les 8h.');
	ok($spanSet->contains($d1_9_59), 'conte el dia 1 a les 9:59h.');
	ok(!$spanSet->contains($d1_10), 'no conte el dia 1 a les 10h.');
	ok(!$spanSet->contains($d4_7), 'no conte el dia 4 a les 7h.');
	ok($spanSet->contains($d4_8), 'conte el dia 4 a les 8h.');
	ok($spanSet->contains($d4_9), 'conte el dia 4 a les 9h.');
	ok($spanSet->contains($d4_9_59), 'conte el dia 4 a les 9:59h.');
	ok(!$spanSet->contains($d4_10), 'no conte el dia 4 a les 10h.');
	ok($spanSet->contains($d7_9_59), 'conte el dia 7 a les 9:59h.');
	ok(!$spanSet->contains($d7_10), 'no conte el dia 7 a les 10h.');
	ok(!$spanSet->contains($d8), 'no conte el dia 8');


	while (my $dt = $spanSet->next ) {
        	# $dt is a DateTime::Span
        	print $dt->min->ymd." ".$dt->min->hms." ";   # first date of span
       		print $dt->max->ymd." ".$dt->max->hms." \n";   # last date of span
    	}

}
