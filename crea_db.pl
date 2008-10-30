#!/usr/bin/perl

use warnings;
use strict;
use Agenda;
use Booking;
use Resource;


use Data::Dumper;


sub datetime {
    my ($year, $month, $day, $hour, $minute) = @_;

    return DateTime->new(
        year   => $year   || '2008',
        month  => $month  || '4',
        day    => $day    || '14',
        hour   => $hour   || '0',
        minute => $minute || '0',
    );
}


my $dades;

if (-e 'foo.db') {
    $dades = require 'foo.db';
    warn Dumper $dades;
}
else {
    # Create an agenda

    my $b1 = Booking->new(datetime(2008, 4, 14, 17),
                      datetime(2008,4,14,18,59));

    my $b2 = Booking->new(datetime(2008,4,14,19),
                      datetime(2008,4,14,19,59));

    my $b3 = Booking->new(datetime(2008,4,14,15),
                      datetime(2008,4,14,17,59));

    my $ag = Agenda->new();

    $ag->append($b1);
    $ag->append($b2);
    $ag->append($b3);

    my $r = Resource->from_xml(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <resource>
            <id>25</id>
            <description>aula chachipilongui</description>
        </resource>");
    


    $dades = {
        agend => $ag
    };
}

print "bye!\n";

END {
    open my $out, ">", "foo.db" or die;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 5;

    print $out Dumper($dades);
    close $out;
}
