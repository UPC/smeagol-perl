#!/usr/bin/perl
use Test::More tests => 26;

use DateTime;

use strict;
use warnings;
use Data::Dumper;

BEGIN { use_ok($_) for qw(Booking Agenda Resource) };

# Make a DateTime object with some defaults
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

# 17:00 - 18:59
my $b1 = Booking->new(datetime(2008, 4, 14, 17),
                      datetime(2008,4,14,18,59));
# 19:00 - 19:59
my $b2 = Booking->new(datetime(2008,4,14,19),
                      datetime(2008,4,14,19,59));
# 15:00 - 17:59
my $b3 = Booking->new(datetime(2008,4,14,15),
                      datetime(2008,4,14,17,59));
# 15:00 - 17:00
my $b4 = Booking->new(datetime(2008,4,14,15),
                      datetime(2008,4,14,17));
# 16:00 - 16:29
my $b5 = Booking->new(datetime(2008,4,14,16),
                      datetime(2008,4,14,16,29));

#to_xml booking test
ok($b1->to_xml() eq "<booking>".
    "<from><year>2008</year><month>4</month><day>14</day><hour>17</hour><minute>0</minute><second>0</second></from>".
    "<to><year>2008</year><month>4</month><day>14</day><hour>18</hour><minute>59</minute><second>0</second></to>".
    "</booking>", 'to_xml booking'); 	

# Booking Equality Tests
ok( $b1 != $b2, 'b1 != b2' );

# Booking Interlacing Tests
ok( !$b1->intersects($b2), 'b1 does not interlace b2' );
ok(  $b1->intersects($b3), 'b1 interlaces b3' );
ok(  $b1->intersects($b4), 'b1 interlaces b4' );
ok(  $b4->intersects($b5), 'b4 interlaces b5' );
ok(  $b5->intersects($b4), 'b5 interlaces b4' );

# Agenda Append Tests
my $ag = Agenda->new();

$ag->append($b1);
ok( $ag->contains($b1), 'b1 in ag' );

#to_xml agenda test
ok($ag->to_xml() eq "<agenda><booking>".
    "<from><year>2008</year><month>4</month><day>14</day><hour>17</hour><minute>0</minute><second>0</second></from>".
    "<to><year>2008</year><month>4</month><day>14</day><hour>18</hour><minute>59</minute><second>0</second></to>".
    "</booking></agenda>", 'to_xml agenda');#

$ag->append($b2);
ok( $ag->size == 2 && $ag->contains($b2), 'b2 also in ag' );

$ag->append($b3);
ok( $ag->size == 2 && !$ag->contains($b3), 'b3 not in ag' );

$ag->append($b4);
ok( $ag->size == 2 && !$ag->contains($b4), 'b4 not in ag' );

# Agenda Remove Tests
ok( $ag->size == 2, 'ag has 2 slots' );

$ag->remove($b1);
ok( $ag->size == 1, 'ag has 1 slot' );

$ag->remove($b2);
ok( $ag->size == 0, 'ag has no slots' );

$ag->remove($b4);
ok( $ag->size == 0, 'remove non-existing b4 from ag' );

# Resource creation Tests
my $r = Resource->from_xml(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
        <resource>
            <id>25</id>
            <description>aula chachipilongui</description>
            <granularity>reserves diaries</granularity>
        </resource>");
ok( $r->{id}   eq "25" && 
    $r->{desc} eq "aula chachipilongui" &&
    $r->{gra}  eq "reserves diaries",
    'resource r created from XML string');

# to_xml Resource test
$r = Resource->new(25, 'aula chachipilongui', 'reserves diaries');
ok( $r->to_xml() eq '<resource>'.
                    '<id>25</id>'.
                    '<description>aula chachipilongui</description>'.
                    '<granularity>reserves diaries</granularity>'.
                    '</resource>', 'to_xml resource' );

$r->{ag}->append($b1);
ok( $r->{ag}->contains($b1), 'b1 in r->ag' );
ok( !$r->{ag}->contains($b2), 'b2 not in r->ag' );
ok( $r->to_xml() eq "<resource><id>25</id><description>aula chachipilongui</description><granularity>reserves diaries</granularity><agenda><booking><from><year>2008</year><month>4</month><day>14</day><hour>17</hour><minute>0</minute><second>0</second></from><to><year>2008</year><month>4</month><day>14</day><hour>18</hour><minute>59</minute><second>0</second></to></booking></agenda></resource>",'to_xml resource with agenda and 1 booking' );
$r->{ag}->append($b2);
ok( $r->{ag}->contains($b2), 'b2 in r->ag' ); #25 test
ok( $r->to_xml() eq 
    "<resource>".
    "<id>25</id>".
    "<description>aula chachipilongui</description>".
    "<granularity>reserves diaries</granularity>".
    "<agenda>".
        "<booking>".
            "<from>".
                "<year>2008</year>".
                "<month>4</month>".
                "<day>14</day>".
                "<hour>17</hour>".
                "<minute>0</minute>".
                "<second>0</second>".
            "</from>".
            "<to>".
                "<year>2008</year>".
                "<month>4</month>".
                "<day>14</day>".
                "<hour>18</hour>".
                "<minute>59</minute>".
                "<second>0</second>".
            "</to>".
        "</booking>".
        "<booking>".
        "<from>".
            "<year>2008</year>".
            "<month>4</month>".
            "<day>14</day>".
            "<hour>19</hour>".
            "<minute>0</minute>".
            "<second>0</second>".
        "</from>".
        "<to>".
            "<year>2008</year>".
            "<month>4</month>".
            "<day>14</day>".
            "<hour>19</hour>".
            "<minute>59</minute>".
            "<second>0</second>".
            "</to></booking></agenda></resource>",'to_xml resource with agenda and 2 bookings' );
