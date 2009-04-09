#!/usr/bin/perl
use Test::More tests => 33;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;

BEGIN { use_ok($_) for qw(Booking Resource Agenda DataStore Tag TagSet) }

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
my $b1 = Booking->new(
    "b1",
    datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 ),
    "info b1",
);

# 19:00 - 19:59
my $b2 = Booking->new(
    "b2",
    datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 ),
    "info b2",
);

# Resource creation Tests
my $resource_as_xml = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<resource>
    <description>aula chachipilongui</description>
    <info>info de l'aula chachipilongui</info>
</resource>
EOF
my $r1 = Resource->from_xml($resource_as_xml);
ok( $r1->description eq "aula chachipilongui"
        && $r1->info eq "info de l'aula chachipilongui",
    'resource r created from XML string'
);

# to_xml Resource test
my $resource_as_hash = {
    description => "aula chachipilongui",
    info        => "info de l'aula chachipilongui",
};
my $r2 = Resource->new( 'aula chachipilongui',
    undef, "info de l'aula chachipilongui" );
my $r2bis = Resource->from_xml( $r2->to_xml(), $r2->id );
ok( $r2bis->description eq 'aula chachipilongui'
        && $r2bis->info eq "info de l'aula chachipilongui",
    'to_xml resource'
);

$r1->agenda->append($b1);
my $ident = $r1->id;
ok( $r1->agenda->contains($b1),  'b1 in r1->ag' );
ok( !$r1->agenda->contains($b2), 'b2 not in r1->ag' );
ok( $r1->to_xml() eq "<resource>"
        . "<description>"
        . $r1->description
        . "</description>"
        . "<agenda>"
        . "<booking>" . "<id>"
        . $b1->id . "</id>"
        . "<description>"
        . $b1->description
        . "</description>"
        . "<from><year>2008</year><month>4</month><day>14</day><hour>17</hour><minute>0</minute><second>0</second></from>"
        . "<to><year>2008</year><month>4</month><day>14</day><hour>18</hour><minute>59</minute><second>0</second></to>"
        . "<info>"
        . $b1->info
        . "</info>"
        . "</booking></agenda>"
        . "<info>"
        . $r1->info
        . "</info>"
        . "</resource>",
    'to_xml resource with agenda and 1 booking: ' . $r1->to_xml()
);
$r1->agenda->append($b2);
ok( $r1->agenda->contains($b2), 'b2 in r->ag' );

my $res = Resource->from_xml( '
<resource>
    <description>aula</description>
    <agenda>
        <booking>
            <id>10</id>
            <description>Hola</description>
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
            <description>Adeu</description>
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
    <info>Hola, soc la info</info>
</resource>' );
ok( $res->description eq 'aula' && $res->info eq 'Hola, soc la info',
    'from_xml resource' );

my $r3;
my ( $tg, $tg1 );
my $tgS;
my $ag;

#create resource with tags
{

    #with agenda
    $tg = Tag->new("aula");
    ok( defined $tg && $tg->value eq "aula", 'tag created ok' );

    $tgS = TagSet->new();
    ok( defined $tgS, 'tagSet created ok' );

    $tgS->append($tg);
    ok( $tgS->size == 1, 'tgS contains 1 tag' );

    $ag = Agenda->new();
    ok( defined $ag, 'ag created ok' );

    $r3 = Resource->new( 'A5123', 'dies', $ag, $tgS );
    ok( defined $r3 && $r3->tags->to_xml() eq "<tags><tag>aula</tag></tags>",
        'resource created ok from data'
    );

    #without agenda
    $tg = Tag->new("aula");
    ok( defined $tg && $tg->value eq "aula", 'tag created ok' );

    $tgS = TagSet->new();
    ok( defined $tgS, 'tagSet created ok' );

    $tgS->append($tg);
    ok( $tgS->size == 1, 'tgS contains 1 tag' );

    $ag = Agenda->new();
    ok( defined $ag, 'ag created ok' );

    $r3 = Resource->new( 'A5123', 'dies', undef, $tgS );
    ok( defined $r3 && $r3->tags->to_xml() eq "<tags><tag>aula</tag></tags>",
        'resource created ok from data'
    );
}

#create resource with tags from_xml
{

    #with agenda
    $r3 = Resource->from_xml( '
		<resource>
		    <description>aula</description>
			<agenda>
        		<booking>
            		<id>10</id>
                    <description>aula amb tags</description>
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
			</agenda>
    		<info>horaria</info>
			<tags>
				<tag>aula</tag>
			</tags>
		</resource>' );
    ok( defined $r3
            && $r3->description  eq 'aula'
            && $r3->info         eq 'horaria'
            && $r3->tags->to_xml eq "<tags><tag>aula</tag></tags>",
        'resource created ok from_xml, with agenda'
    );

    #without agenda
    $r3 = Resource->from_xml( '
		<resource>
		    <description>aula</description>
    		<info>horaria</info>
			<tags>
				<tag>aula</tag>
			</tags>
		</resource>' );
    ok( defined $r3
            && $r3->description  eq 'aula'
            && $r3->info         eq 'horaria'
            && $r3->tags->to_xml eq "<tags><tag>aula</tag></tags>",
        'resource created ok from_xml, without agenda'
    );

}

#updating tags
{
    $r3 = Resource->from_xml( '
		<resource>
		    <description>aula</description>
    		<info>horaria</info>
			<tags>
				<tag>aula</tag>
			</tags>
		</resource>' );
    ok( defined $r3
            && $r3->description  eq 'aula'
            && $r3->info         eq 'horaria'
            && $r3->tags->to_xml eq "<tags><tag>aula</tag></tags>",
        'resource created ok'
    );

    $tg = Tag->new("projector");
    ok( defined $tg && $tg->value eq "projector", 'tag created ok' );

    $tg1 = Tag->new("campus:nord");
    ok( defined $tg1 && $tg1->value eq "campus:nord", 'tag created ok' );

    $tgS = TagSet->new();
    ok( defined $tgS, 'tagSet created ok' );

    $tgS->append($tg);
    $tgS->append($tg1);
    ok( $tgS->size == 2, 'tagSet with 2 tags' );

    ok( $r3->tags->size == 1, 'resource tagSet with 1 tags' );
    $r3->tags($tgS);
    ok( $r3->tags->size == 2, 'resource tagSet updated with 2 tags' );

    my $values;
    foreach ( $r3->tags->elements ) {
        $values .= " " . $_->value;
    }
    ok( $values =~ /projector/
            && $values =~ /campus:nord/
            && $values !~ /aula/,
        'resource tagSet retrieved ok'
    );
}

END {
    DataStore->clean();
}
