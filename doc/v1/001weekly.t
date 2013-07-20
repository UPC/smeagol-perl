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
        DateTime::Event::ICal
    );
}

# Smeagol meetings: weekly, on thursdays from 9:30 to 14:00
{

  # build an interval (DateTime::Span) to be used in DateTime::Set constructor
    my @selectedDays = [ 'th' ]; # thursday
    my $begin = DateTime->from_epoch( epoch=> 0 );
    my $end = DateTime::Infinite::Future->new;

    # first, build a DateTime::Set
    my $set = DateTime::Event::ICal->recur(
        dtstart => $begin,
        dtend => $end,
        freq => 'weekly',
        byday => @selectedDays,
        byhour => [ 9 ],
        byminute => [ 30 ],
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
    my @selectedDays = [ 'mo', 'we', 'fr' ]; # monday, wednesday, friday
    my $begin    = DateTime->from_epoch( epoch => 0 );
    my $end      = DateTime::Infinite::Future->new;

    my $set = DateTime::Event::ICal->recur(
        dtstart => $begin,
        until => $end,
        freq => 'weekly',
        byday => @selectedDays,
        byhour => [ 15 ],
        byminute => [ 0 ],
    );

    my $duration = DateTime->new( year => 1970, hour => 17, minute => 0 )
        - DateTime->new( year => 1970, hour => 15, minute => 0 );

    my $spanSet = DateTime::SpanSet->from_set_and_duration(
        set      => $set,
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
    my @selectedDays = [ 'mo' ];
    my $begin    = DateTime->from_epoch( epoch => 0 );
    my $end      = DateTime::Infinite::Future->new;

    my $set = DateTime::Event::ICal->recur(
        dtstart => $begin,
        dtend => $end,
        freq => 'weekly',
        byday => @selectedDays,
        interval => $multiplier,
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
        1970-01-26T00:00:00
        1970-02-23T00:00:00
        1970-03-23T00:00:00
        1970-04-20T00:00:00
        1970-05-18T00:00:00
    );
    my @expectedEnd = qw(
        1970-01-27T00:00:00
        1970-02-24T00:00:00
        1970-03-24T00:00:00
        1970-04-21T00:00:00
        1970-05-19T00:00:00
    );
    is_deeply( \@gotStart, \@expectedStart, "recurrence matches selected start times" );
    is_deeply( \@gotEnd, \@expectedEnd, "recurrence matches selected end times" );

}

done_testing();
