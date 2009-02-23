#!/usr/bin/perl
use Test::More tests => 11;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;

BEGIN { use_ok($_) for qw(Booking Resource Agenda DataStore) }

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
    <description>aula chachipilongui</description>
    <granularity>reserves diaries</granularity>
</resource>
EOF
my $r1 = Resource->from_xml($resource_as_xml);
ok( $r1->description eq "aula chachipilongui"
        && $r1->granularity eq "reserves diaries",
    'resource r created from XML string'
);

# to_xml Resource test
my $resource_as_hash = {
    description => "aula chachipilongui",
    granularity => "reserves diaries",
};
my $r2 = Resource->new( 'aula chachipilongui', 'reserves diaries' );
my $r2bis = Resource->from_xml( $r2->to_xml(), $r2->id );
ok( $r2bis->description eq 'aula chachipilongui'
        && $r2bis->granularity eq 'reserves diaries',
    'to_xml resource'
);

$r1->agenda->append($b1);
my $ident = $r1->id;
ok( $r1->agenda->contains($b1),  'b1 in r1->ag' );
ok( !$r1->agenda->contains($b2), 'b2 not in r1->ag' );
ok( $r1->to_xml() eq
        "<resource><description>aula chachipilongui</description><granularity>reserves diaries</granularity><agenda><booking><id>".$b1->id."</id><from><year>2008</year><month>4</month><day>14</day><hour>17</hour><minute>0</minute><second>0</second></from><to><year>2008</year><month>4</month><day>14</day><hour>18</hour><minute>59</minute><second>0</second></to></booking></agenda></resource>",
    'to_xml resource with agenda and 1 booking: ' . $r1->to_xml()
);
$r1->agenda->append($b2);
ok( $r1->agenda->contains($b2), 'b2 in r->ag' );

my $res = Resource->from_xml( '
<resource>
    <description>aula</description>
    <granularity>horaria</granularity>
    <agenda>
        <booking>
            <id>10</id>
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
            <id>25</id>
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
ok(        $res->description eq 'aula'
        && $res->granularity eq 'horaria'
        && 'from_xml resource' );

END {
    DataStore->clean();
}
