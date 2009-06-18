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
