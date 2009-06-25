#!/usr/bin/perl

use Test::More tests => 15;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(
        DateTime
        DateTime::Span
        DateTime::Set
        DateTime::SpanSet
    );
}

my ($start, $end, $span, $set, $duration, $spanSet , @localtime);



#cada agost anualment
{
	$start	= DateTime->from_epoch( epoch=> 0 );
    $end	= DateTime::Infinite::Future->new;
#	$end = DateTime->new( year => 2009, month => 12 , day => 1);

	$span	= DateTime::Span->from_datetimes( start => $start, end => $end );

	$set = DateTime::Set->from_recurrence(
		span => $span,
		recurrence => sub {
				my $dt = shift;
				return $dt->add(years => 1);
		}
	);

	$duration = DateTime->new( year => 1970, month => 8 , day => 31, hour => 23, minute => 59 , second => 59 )
				 - DateTime->new( year => 1970, month => 8 , day => 1,  hour => 0, minute => 0 );
	
	$spanSet = DateTime::SpanSet->from_set_and_duration(
	        set      => $set,
	        duration => $duration
	    );
=pod
	while (my $dt = $spanSet->next ) {
        	# $dt is a DateTime::Span
        	print $dt->min->ymd." ".$dt->min->hms." ";   # first date of span
       		print $dt->max->ymd." ".$dt->max->hms." \n";   # last date of span
    	}
=cut
}

#cada agost anualment, a partir de avui
{
	@localtime = localtime();
    $start	= DateTime->new( year => $localtime[5]+1900, month => $localtime[4]+1, day => $localtime[3], hour => $localtime[2], minute => $localtime[1]);
	$end = DateTime->new( year => 2010, month => 12 , day => 1);

	$span	= DateTime::Span->from_datetimes( start => $start, end => $end );

	$set = DateTime::Set->from_recurrence(
		span => $span,
		recurrence => sub {
				my $dt = shift;
				if($dt->month < 8){
					$dt->truncate( to => 'year' );
					return $dt->add(months => 7);
				}else{
					$dt->truncate( to => 'year' );
					return $dt->add(years => 1);
				}
		}
	);

	$duration = DateTime->new( year => 1970, month => 8 , day => 31, hour => 23, minute => 59 , second => 59 )
				 - DateTime->new( year => 1970, month => 8 , day => 1,  hour => 0, minute => 0 );
	
	$spanSet = DateTime::SpanSet->from_set_and_duration(
	        set      => $set,
	        duration => $duration
	    );

	while (my $dt = $spanSet->next ) {
        	# $dt is a DateTime::Span
        	print $dt->min->ymd." ".$dt->min->hms." ";   # first date of span
       		print $dt->max->ymd." ".$dt->max->hms." \n";   # last date of span
   	}
}
