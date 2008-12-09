#!/usr/bin/perl
use Test::More tests => 11;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;

BEGIN { use_ok($_) for qw(Booking Resource Agenda) }

# Make a DateTime object with some defaults
sub datetime {
    my ( $year, $month, $day, $hour, $minute ) = @_;

    return DateTime->new(
        year   => $year   || '2008',
        month  => $month  || '4',
        day    => $day    || '14',
        hour   => $hour   || '0',
        minute => $minute || '0'
    );
}

# 17:00 - 18:59
my $b1 = Booking->new( datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 ) );

# 19:00 - 19:59
my $b2 = Booking->new( datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 ) );

# Resource creation Tests
my $resource_as_xml = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<resource>
    <id>25</id>
    <description>aula chachipilongui</description>
    <granularity>reserves diaries</granularity>
</resource>
EOF
my $r1 = Resource->from_xml($resource_as_xml);
ok( $r1->{id}          eq "25"
        && $r1->{desc} eq "aula chachipilongui"
        && $r1->{gra}  eq "reserves diaries",
    'resource r created from XML string'
);

# to_xml Resource test
my $resource_as_hash = {
    id          => 25,
    description => "aula chachipilongui",
    granularity => "reserves diaries",
};
my $r2 = Resource->new( 25, 'aula chachipilongui', 'reserves diaries' );
ok( Compare( XMLin( $r2->to_xml() ), $resource_as_hash ), 'to_xml resource' );

$r1->{ag}->append($b1);
ok( $r1->{ag}->contains($b1),  'b1 in r1->ag' );
ok( !$r1->{ag}->contains($b2), 'b2 not in r1->ag' );
ok( $r1->to_xml() eq
        "<resource><id>25</id><description>aula chachipilongui</description><granularity>reserves diaries</granularity><agenda><booking><from><year>2008</year><month>4</month><day>14</day><hour>17</hour><minute>0</minute><second>0</second></from><to><year>2008</year><month>4</month><day>14</day><hour>18</hour><minute>59</minute><second>0</second></to></booking></agenda></resource>",
    'to_xml resource with agenda and 1 booking'
);
$r1->{ag}->append($b2);
ok( $r1->{ag}->contains($b2), 'b2 in r->ag' );

$resource_as_hash = {
    id          => 25,
    description => "aula chachipilongui",
    granularity => "reserves diaries",
    agenda      => {
        booking => [
            {   from => {
                    year   => 2008,
                    month  => 4,
                    day    => 14,
                    hour   => 17,
                    minute => 0,
                    second => 0,
                },
                to => {
                    year   => 2008,
                    month  => 4,
                    day    => 14,
                    hour   => 18,
                    minute => 59,
                    second => 0,
                },
            },
            {   from => {
                    year   => 2008,
                    month  => 4,
                    day    => 14,
                    hour   => 19,
                    minute => 0,
                    second => 0,
                },
                to => {
                    year   => 2008,
                    month  => 4,
                    day    => 14,
                    hour   => 19,
                    minute => 59,
                    second => 0,
                },
            },

        ],
    },
};
ok( Compare( XMLin( $r1->to_xml() ), $resource_as_hash ),
    'to_xml resource with agenda and 2 bookings'
);

my $res = Resource->from_xml( '
<resource>
    <id>3</id>
    <description>aula</description>
    <granularity>horaria</granularity>
    <agenda>
        <booking>
            <from>
                <year>2008</year>
                <month>4</month>
                <day>14</day>
                <hour>19</hour>
                <minute>0</minute>
                <second>0</second>
            </from>
            <to>
                <year>2008</year>
                <month>4</month>
                <day>14</day>
                <hour>19</hour>
                <minute>59</minute>
                <second>0</second>
            </to>
        </booking>
        <booking>
            <from>
                <year>2008</year>
                <month>4</month>
                <day>14</day>
                <hour>17</hour>
                <minute>0</minute>
                <second>0</second>
            </from>
            <to>
                <year>2008</year>
                <month>4</month>
                <day>14</day>
                <hour>18</hour>
                <minute>59</minute>
                <second>0</second>
            </to>
        </booking>
    </agenda>
</resource>' );
ok(        $res->{id} eq '3'
        && $res->{desc} eq 'aula'
        && $res->{gra}  eq 'horaria'
        && 'from_xml resource' );

END { unlink </tmp/smeagol_datastore/*.db> }
