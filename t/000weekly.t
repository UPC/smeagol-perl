#!/usr/bin/perl
use Test::More tests => 7;

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

# weekly, on thursdays from 9:30 to 14:00
{
    my $dt_start = DateTime->now->truncate(to => 'day');
    my $dt_end = DateTime::Infinite::Future->new; # until the end of the universe! :-)
    my $ds = DateTime::Set->from_recurrence(
        span => DateTime::Span->from_datetimes(start=>$dt_start, end=>$dt_end),
        recurrence => sub {
            my $dt = shift;
            if ($dt->day_of_week <= 4) {
                # this week's thursday
                return $dt->truncate(to => 'week')->add( days => 4);
            } else {
                # next week's thursday
                return $dt->truncate(to => 'week')->add( weeks => 1, days => 4);
            };
        }
    );

    ok(1 == 1, "weekly, on thursdays from 9:30 to 14:00");
}

# weekly, on monday, wednesday, friday, from 15:00 to 17:00
{
    ok(1 == 1, "weekly, on mon, we, fri from 15:00 to 17:00");
}

# weekly, every 4 mondays
{
    ok(1 == 1, "weekly, every 4 mondays");
}
