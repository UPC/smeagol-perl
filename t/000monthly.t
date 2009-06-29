#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 3;

use DateTime::Set;

# last Thu of the month
TODO: {
    local $TODO = "working in progress";

    my $recurrence = sub {
        my ($dt) = @_;

        my $currentThu = $dt->clone
                         ->add( weeks => 1 )
                         ->truncate( to => 'week' )
                         ->add( days=> 3 );
        warn ">>> currentThu: " . $currentThu->ymd . "\n";
        my $nextThu = $currentThu->clone->add( weeks => 1 );
        warn ">>> nextThu: " . $nextThu->ymd . "\n";

        # test whether it is the last Thu of the month and set step
        my $step = $currentThu->month == $nextThu->month ? 1 : 2;

        return $dt->add( months => $step )
                  ->truncate( to => 'month' )
                  ->subtract( weeks => 1 )
                  ->truncate( to => 'week' )
                  ->add( days => 3 );
    };

    my $dtSpan = DateTime::Span->from_datetimes(
        start => DateTime->from_epoch( epoch => 0 ),
        end   => DateTime::Infinite::Future->new,
    );

    my $dtSet = DateTime::Set->from_recurrence(
        span => $dtSpan,
        recurrence => $recurrence,
    );

    my $dtIter = $dtSet->iterator;
    warn $dtIter->next->ymd . "\n" for 1 .. 10;

    ok(0);
}

# each day 10 of the month, 10:00-14:00
TODO: {
    local $TODO = "work in progress";

    # XXX: weird things happen with day 31
    my $monthDay = 10;
    my $recurrence = sub {
        my ($dt) = @_;

        my $day = $dt->day;
        $dt = $dt->truncate( to => 'month' );

        if ( $day < $monthDay ) {
            return $dt->add( days => $monthDay - 1 );
        }
        else {
            return $dt->add( months => 1, days => $monthDay - 1 );
        }
    };

    #my $now = DateTime->now;
    #my $oneYearLater = DateTime::Duration->new( years => 1 );
    my $dtSpan = DateTime::Span->from_datetimes(
        #start => $now,
        #end   => $now + $oneYearLater,
        start => DateTime->from_epoch( epoch => 0 ),
        end   => DateTime::Infinite::Future->new,
    );

    my $dtSet = DateTime::Set->from_recurrence(
        span => $dtSpan,
        recurrence => $recurrence,
    );

    my @got;
    my $dtIter = $dtSet->iterator;
    push @got, $dtIter->next->ymd for 1 .. 13;

    my @expected = qw(
        1970-01-10
        1970-02-10
        1970-03-10
        1970-04-10
        1970-05-10
        1970-06-10
        1970-07-10
        1970-08-10
        1970-09-10
        1970-10-10
        1970-11-10
        1970-12-10
        1971-01-10
    );

    is_deeply( \@got, \@expected, "10th day recurrences since epoch (test 8)" );
}

# last day of the month
TODO: {
    local $TODO = "work in progress";

    my $recurrence = sub {
        my ($dt) = @_;

        # test whether it is the last day of the month and set step
        my $step = $dt->add( days => 1 )->month == $dt->month ? 1 : 2;

        return $dt->add( months => $step )
                  ->truncate( to => 'month' )
                  ->subtract( days => 1 );
    };

    my $dtSpan = DateTime::Span->from_datetimes(
        start => DateTime->from_epoch( epoch => 0 ),
        end   => DateTime::Infinite::Future->new,
    );

    my $dtSet = DateTime::Set->from_recurrence(
        span => $dtSpan,
        recurrence => $recurrence,
    );

    my @got;
    my $dtIter = $dtSet->iterator;
    push @got, $dtIter->next->ymd for 1 .. 26;

    my @expected = qw(
        1970-01-31
        1970-02-28
        1970-03-31
        1970-04-30
        1970-05-31
        1970-06-30
        1970-07-31
        1970-08-31
        1970-09-30
        1970-10-31
        1970-11-30
        1970-12-31
        1971-01-31
        1971-02-28
        1971-03-31
        1971-04-30
        1971-05-31
        1971-06-30
        1971-07-31
        1971-08-31
        1971-09-30
        1971-10-31
        1971-11-30
        1971-12-31
        1972-01-31
        1972-02-29
    );

    is_deeply( \@got, \@expected, "last day of the month (test 9)" );
}
