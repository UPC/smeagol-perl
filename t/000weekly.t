#!/usr/bin/perl
use Test::More tests => 12;

use strict;
use warnings;

BEGIN {
    use_ok($_) for qw(
        DateTime
        DateTime::Span
        DateTime::Set
        DateTime::SpanSet
    );
}

# Make a DateTime object with some defaults
sub datetime {
    my ( $year, $month, $day, $hour, $minute ) = @_;

    return DateTime->new(
        year   => $year   || '2008',
        month  => $month  || '4',
        day    => $day    || '14',
        hour   => $hour   || '0',
        minute => $minute || '0',
    );
}

# Smeagol meetings: weekly, on thursdays from 9:30 to 14:00
{

  # build an interval (DateTime::Span) to be used in DateTime::Set constructor
    my $begin = DateTime->from_epoch( epoch=> 0 );
    my $end = DateTime::Infinite::Future->new;
    my $interval
        = DateTime::Span->from_datetimes( start => $begin, end => $end );

    # first, build a DateTime::Set
    my $set = DateTime::Set->from_recurrence(
        span       => $interval,
        recurrence => sub {
            my $dt = shift;
            if ( $dt->day_of_week < 4 ) {    # monday=1, thursday=4

                # this week's thursday
                $dt = $dt->truncate( to => 'week' )->add( days => 3 );
            }
            else {

                # next week's thursday
                $dt = $dt->truncate( to => 'week' )
                    ->add( weeks => 1, days => 3 );
            }

            return $dt->add( hours => 9, minutes => 30 );
        }
    );

    # build a duration (9:30 - 14:00) to be used in SpanSet constructor
    my $duration = DateTime->new( year => 1970, hour => 14, minute => 0 )
        - DateTime->new( year => 1970, hour => 9, minute => 30 );

    # apply a duration to each member of $set (convert to SpanSet)
    my $spanSet = DateTime::SpanSet->from_set_and_duration(
        set      => $set,
        duration => $duration
    );

    # are we meeting next thursday?
    my $next = $spanSet->next( DateTime->now );
    ok( $next->start->day_of_week == 4,
        "next booking day of week is thursday"
    );
    ok( $next->start->hms eq "09:30:00", "next booking start time is 9:30" );
    ok( $next->end->hms   eq "14:00:00", "next booking end time is 14:00" );

    # mmmhh... okay, let's see wether the Smeagol team will
    # still celebrate meetings in a few years...
    $next = $spanSet->next( DateTime->now->add( years => 20 ) );
    ok( $next->start->day_of_week == 4, "day of week is thursday" );
    ok( $next->start->hms eq "09:30:00", "booking start time is 9:30" );
    ok( $next->end->hms   eq "14:00:00", "booking end time is 14:00" );

}

# weekly, on monday, wednesday, friday, from 15:00 to 17:00
{
    my @selectedDays = ( 1, 3, 5 );    # monday, wednesday, friday
    my $begin    = DateTime->from_epoch( epoch => 0 );
    my $end      = DateTime::Infinite::Future->new;
    my $interval = DateTime::Span->from_datetimes( start => $begin, end => $end );

    warn "Hola\n";
    my $set = DateTime::Set->from_recurrence(
        span       => $interval,
        recurrence => sub {
            my $dt = shift;
            $dt = $dt->truncate(to => 'day');
            while ( !(grep {$_ == $dt->day_of_week} @selectedDays) ) {
                $dt = $dt->add( days => 1 );
            }
            return $dt->add( hours => 15, minutes => 0 );
        }
    );

    my $duration = DateTime->new( year => 1970, hour => 17, minute => 0 )
        - DateTime->new( year => 1970, hour => 15, minute => 0 );

    warn "Hola\n";
    my $spanSet = DateTime::SpanSet->from_set_and_duration(
        set      => $set,
        duration => $duration
    );

    warn "Hola\n";

    my $iter = $spanSet->iterator;
    my @got;
    for ( my $i = 0; $i < 10; $i++) {
        push @got, $iter->next->start->day_of_week;
    }
    #push @got, $iter->next->start->day_of_week for 1 .. 10;
    # Jan 1, 1970 was thursday, so first day matching 
    # recurrence in @selectedDays must be friday (day_of_week = 5)
    print @got;
    my @expected = (5, 1, 3, 5, 1, 3, 5, 1, 3, 5);

    is_deeply(\@got, \@expected, "Recurrence matches selected days");
    #ok( 1 == 1, "weekly, on mon, we, fri from 15:00 to 17:00" );
}

# weekly, every 4 mondays
TODO: {
    todo_skip 'not implemented', 1;
    ok( 1 == 1, "weekly, every 4 mondays" );
}
