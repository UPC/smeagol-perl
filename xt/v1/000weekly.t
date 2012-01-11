#!/usr/bin/perl
use Test::More;

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
    my $selectedDay = 4; # thursday = 4
    my $begin = DateTime->from_epoch( epoch=> 0 );
    my $end = DateTime::Infinite::Future->new;
    my $interval
        = DateTime::Span->from_datetimes( start => $begin, end => $end );

    # first, build a DateTime::Set
    my $set = DateTime::Set->from_recurrence(
        span       => $interval,
        recurrence => sub {
            my $dt = shift;
            if ( $dt->day_of_week < $selectedDay ) {    # monday=1, thursday=4

                # this week's thursday
                $dt = $dt->truncate( to => 'week' )->add( days => $selectedDay - 1 );
            }
            else {

                # next week's thursday
                $dt = $dt->truncate( to => 'week' )
                    ->add( weeks => 1, days => $selectedDay - 1 );
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
    ok( $next->start->day_of_week == $selectedDay,
        "next booking day of week is thursday"
    );
    ok( $next->start->hms eq "09:30:00", "next booking start time is 9:30" );
    ok( $next->end->hms   eq "14:00:00", "next booking end time is 14:00" );

    # mmmhh... okay, let's see wether the Smeagol team will
    # still celebrate meetings in a few years...
    $next = $spanSet->next( DateTime->now->add( years => 20 ) );
    ok( $next->start->day_of_week == $selectedDay, "day of week is thursday" );
    ok( $next->start->hms eq "09:30:00", "booking start time is 9:30" );
    ok( $next->end->hms   eq "14:00:00", "booking end time is 14:00" );

}

# weekly, on monday, wednesday, friday, from 15:00 to 17:00
{
    my @selectedDays = ( 1, 3, 5 );    # monday, wednesday, friday
    my $begin    = DateTime->from_epoch( epoch => 0 );
    my $end      = DateTime::Infinite::Future->new;
    my $interval = DateTime::Span->from_datetimes( start => $begin, end => $end );

    my $totalSet = DateTime::Set->empty_set;

    foreach my $day ( @selectedDays ) {
        my $set = DateTime::Set->from_recurrence(
            span => $interval,
            recurrence => sub {
                my $dt = shift;
                $dt = $dt->truncate(to => 'day');
                if ( $dt->day_of_week < $day ) {
                    $dt = $dt->truncate(to => 'week')->add(days => $day - 1);
                } else {
                    $dt = $dt->truncate(to => 'week')->add(weeks=>1, days=> $day - 1);
                }
                return $dt->add( hours=> 15, minutes=> 0 );
            }
        );
        $totalSet = $totalSet->union($set);
    }

    my $duration = DateTime->new( year => 1970, hour => 17, minute => 0 )
        - DateTime->new( year => 1970, hour => 15, minute => 0 );

    my $spanSet = DateTime::SpanSet->from_set_and_duration(
        set      => $totalSet,
        duration => $duration
    );

    my $iter = $spanSet->iterator;
    my @gotDayOfWeek;
    my @gotTimeStart;
    my @gotTimeEnd;
    push @gotDayOfWeek, $iter->next->start->day_of_week for 1 .. 10;
    push @gotTimeStart, $iter->next->start->hms for 1 .. 3;
    push @gotTimeEnd, $iter->next->end->hms for 1 .. 3;
    # Jan 1, 1970 was thursday, so first day matching 
    # recurrence in @selectedDays must be friday (day_of_week = 5)
    my @expectedDayOfWeek = (5, 1, 3, 5, 1, 3, 5, 1, 3, 5);
    my @expectedTimeStart = qw(
        15:00:00
        15:00:00
        15:00:00
    );
    my @expectedTimeEnd = qw(
        17:00:00
        17:00:00
        17:00:00
    );
    is_deeply(\@gotDayOfWeek, \@expectedDayOfWeek, "Recurrence matches selected days");
    is_deeply(\@gotTimeStart, \@expectedTimeStart, "Recurrence matches selected start time");
    is_deeply(\@gotTimeEnd, \@expectedTimeEnd, "Recurrence matches selected end time");
}

# weekly, every 4 mondays
{
    my $multiplier = 4; # every 4 weeks
    my $begin    = DateTime->from_epoch( epoch => 0 );
    my $end      = DateTime::Infinite::Future->new;
    my $interval = DateTime::Span->from_datetimes( start => $begin, end => $end );

    my $set = DateTime::Set->from_recurrence(
        span => $interval,
        recurrence => sub {
            my $dt = shift;
            $dt = $dt->truncate( to => 'day' );
            if ( $dt->day_of_week > 1 ) {
                $dt = $dt->truncate( to => 'week' )->add( weeks=> 1 );
            } else {
                $dt->truncate( to => 'week' )->add( weeks => $multiplier );
            }
            return $dt;
        }
    );

    # when no start and end times are specified, 
    # a duration of 1 day is assumed
    my $duration = DateTime::Duration->new( days => 1 );
    my $dset = DateTime::SpanSet->from_set_and_duration(
        set => $set,
        duration => $duration
    );

    my @gotStart;
    my @gotEnd;
    my $iter = $dset->iterator;
    push @gotStart, $iter->next->start for 1 .. 5;
    $iter = $dset->iterator;
    push @gotEnd, $iter->next->end for 1 .. 5;
    my @expectedStart = qw(
        1970-01-05T00:00:00
        1970-02-02T00:00:00
        1970-03-02T00:00:00
        1970-03-30T00:00:00
        1970-04-27T00:00:00
    );
    my @expectedEnd = qw(
        1970-01-06T00:00:00
        1970-02-03T00:00:00
        1970-03-03T00:00:00
        1970-03-31T00:00:00
        1970-04-28T00:00:00
    );
    is_deeply( \@gotStart, \@expectedStart, "recurrence matches selected start times" );
    is_deeply( \@gotEnd, \@expectedEnd, "recurrence matches selected end times" );

}

done_testing();
