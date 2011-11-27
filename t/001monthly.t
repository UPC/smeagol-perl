#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 3;

use DateTime::Set;
use DateTime::Event::ICal;

# last Thu of the month
{
    my $dtSet = DateTime::Event::ICal->recur(
        dtstart => DateTime->from_epoch( epoch => 0 ),
        freq    => 'monthly',
        byday => [ '-1th' ],
    );

    my @got;
    my $dtIter = $dtSet->iterator;
    push @got, $dtIter->next->ymd for 1 .. 10;

    my @expected = qw(
        1970-01-29
        1970-02-26
        1970-03-26
        1970-04-30
        1970-05-28
        1970-06-25
        1970-07-30
        1970-08-27
        1970-09-24
        1970-10-29
    );

    is_deeply( \@got, \@expected, "last Thu of month (test 7)" );
}

# each day 10 of the month, 10:00-14:00
{
    my $dtSet = DateTime::Event::ICal->recur(
        dtstart    => DateTime->from_epoch( epoch => 0 ),
        freq       => 'monthly',
        bymonthday => [ 10 ],
        byhour     => [ 10 ],
    );

    my $dtSpanSet = DateTime::SpanSet->from_set_and_duration(
        set => $dtSet,
        hours => 4,
    );

    my @got;
    my $dtIter = $dtSpanSet->iterator;
    for ( 1 .. 13 ) {
        my $dtSpan = $dtIter->next;
        my $start = $dtSpan->start->datetime;
        my $end   = $dtSpan->end->datetime;

        push @got, [ $start, $end ];
    }

    my @expected = (
        [qw( 1970-01-10T10:00:00 1970-01-10T14:00:00 )],
        [qw( 1970-02-10T10:00:00 1970-02-10T14:00:00 )],
        [qw( 1970-03-10T10:00:00 1970-03-10T14:00:00 )],
        [qw( 1970-04-10T10:00:00 1970-04-10T14:00:00 )],
        [qw( 1970-05-10T10:00:00 1970-05-10T14:00:00 )],
        [qw( 1970-06-10T10:00:00 1970-06-10T14:00:00 )],
        [qw( 1970-07-10T10:00:00 1970-07-10T14:00:00 )],
        [qw( 1970-08-10T10:00:00 1970-08-10T14:00:00 )],
        [qw( 1970-09-10T10:00:00 1970-09-10T14:00:00 )],
        [qw( 1970-10-10T10:00:00 1970-10-10T14:00:00 )],
        [qw( 1970-11-10T10:00:00 1970-11-10T14:00:00 )],
        [qw( 1970-12-10T10:00:00 1970-12-10T14:00:00 )],
        [qw( 1971-01-10T10:00:00 1971-01-10T14:00:00 )],
    );

    is_deeply( \@got, \@expected, "10th day recurrences since epoch (test 8)" );
}

# last day of the month
{
    my $dtSet = DateTime::Event::ICal->recur(
        dtstart => DateTime->from_epoch( epoch => 0 ),
        freq    => 'monthly',
        bymonthday => [ -1 ],
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
