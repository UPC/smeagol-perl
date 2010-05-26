#!/usr/bin/perl
use Test::More tests => 38;

use strict;
use warnings;

use DateTime;
use XML::Simple;
use Data::Compare;
use Encode;
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(
        Smeagol::Booking
        Smeagol::Resource
        Smeagol::Agenda
        Smeagol::DataStore
        Smeagol::Tag
        Smeagol::TagSet
    );

    Smeagol::DataStore::init();
}

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
my $b1 = Smeagol::Booking->new(
    "b1",
    datetime( 2008, 4, 14, 17 ),
    datetime( 2008, 4, 14, 18, 59 ),
    "info b1",
);

# 19:00 - 19:59
my $b2 = Smeagol::Booking->new(
    "b2",
    datetime( 2008, 4, 14, 19 ),
    datetime( 2008, 4, 14, 19, 59 ),
    "info b2",
);

# Resource creation Tests
my $resourceAsXML = <<'EOF';
<?xml version="1.0" encoding="UTF-8"?>
<resource>
    <description>aula chachipilongui</description>
    <info>info de l'aula chachipilongui</info>
</resource>
EOF
my $r1 = Smeagol::Resource->newFromXML($resourceAsXML);
ok( $r1->description eq "aula chachipilongui"
        && $r1->info eq "info de l'aula chachipilongui",
    'resource r created from XML string'
);

# toXML Resource test
my $resourceAsHash = {
    description => "aula chachipilongui",
    info        => "info de l'aula chachipilongui",
};
my $r2 = Smeagol::Resource->new( 'aula chachipilongui',
    undef, "info de l'aula chachipilongui" );
my $r2bis = Smeagol::Resource->newFromXML( $r2->toXML(), $r2->id );
ok( $r2bis->description eq 'aula chachipilongui'
        && $r2bis->info eq "info de l'aula chachipilongui",
    'to_xml resource'
);

$r1->agenda->append($b1);
my $ident = $r1->id;
ok( $r1->agenda->contains($b1),  'b1 in r1->ag' );
ok( !$r1->agenda->contains($b2), 'b2 not in r1->ag' );
$resourceAsHash = {
    description => $r1->description,
    agenda      => {
        booking => {
            id          => $b1->id,
            description => $b1->description,
            from        => {
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
            info => $b1->info,
        },
    },
    info => $r1->info,
};
ok( Compare( $resourceAsHash, XMLin( $r1->toString ) ),
    'resource->toString with agenda and 1 booking'
);

$r1->agenda->append($b2);
ok( $r1->agenda->contains($b2), 'b2 in r->ag' );

my $res = Smeagol::Resource->newFromXML( '
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
my ( $tg, $tg1, $tg2 );
my $tgS;
my $ag;

#create resource with tags
{

    #with agenda
    $tg = Smeagol::Tag->new("aula");
    ok( defined $tg && $tg->value eq "aula", 'tag created ok' );

    $tgS = Smeagol::TagSet->new();
    ok( defined $tgS, 'tagSet created ok' );

    $tgS->append($tg);
    ok( $tgS->size == 1, 'tgS contains 1 tag' );

    $ag = Smeagol::Agenda->new();
    ok( defined $ag, 'ag created ok' );

    $r3 = Smeagol::Resource->new( 'A5123', 'dies', $ag, $tgS );
    my $tagsAsHash = { tag => 'aula', };
    ok( defined $r3 && Compare( $tagsAsHash, XMLin( $r3->tags->toString ) ),
        'resource created ok from data' );

    #without agenda
    $tg = Smeagol::Tag->new("aula");
    ok( defined $tg && $tg->value eq "aula", 'tag created ok' );

    $tgS = Smeagol::TagSet->new();
    ok( defined $tgS, 'tagSet created ok' );

    $tgS->append($tg);
    ok( $tgS->size == 1, 'tgS contains 1 tag' );

    $ag = Smeagol::Agenda->new();
    ok( defined $ag, 'ag created ok' );

    $r3 = Smeagol::Resource->new( 'A5123', 'dies', undef, $tgS );
    ok( defined $r3 && Compare( $tagsAsHash, XMLin( $r3->tags->toString ) ),
        'resource created ok from data' );
}

#create resource with tags newFromXML
{

    #with agenda
    $r3 = Smeagol::Resource->newFromXML( '
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

    my $tagsAsHash = { tag => 'aula', };

    ok( defined $r3
            && $r3->description eq 'aula'
            && $r3->info        eq 'horaria'
            && Compare( $tagsAsHash, XMLin( $r3->tags->toString ) ),
        'resource->newFromXML created, with agenda'
    );

    #without agenda
    $r3 = Smeagol::Resource->newFromXML( '
                <resource>
		    <description>aula</description>
                    <info>horaria</info>
                    <tags>
	                <tag>aula</tag>
                    </tags>
                </resource>' );
    ok( defined $r3
            && $r3->description eq 'aula'
            && $r3->info        eq 'horaria'
            && $r3->agenda->size == 0
            && Compare( $tagsAsHash, XMLin( $r3->tags->toString ) ),
        'resource->newFromXML created, without agenda'
    );

}

#updating tags
{
    $r3 = Smeagol::Resource->newFromXML( '
		<resource>
		    <description>aula</description>
    		<info>horaria</info>
			<tags>
				<tag>aula</tag>
			</tags>
		</resource>' );
    my $tagsAsHash = { tag => 'aula', };

    ok( defined $r3
            && $r3->description eq 'aula'
            && $r3->info        eq 'horaria'
            && Compare( $tagsAsHash, XMLin( $r3->tags->toString ) ),
        'resource created ok'
    );

    $tg = Smeagol::Tag->new("projector");
    ok( defined $tg && $tg->value eq "projector", 'tag created ok' );

    $tg1 = Smeagol::Tag->new("campus:nord");
    ok( defined $tg1 && $tg1->value eq "campus:nord", 'tag created ok' );

    $tgS = Smeagol::TagSet->new();
    ok( defined $tgS, 'tagSet created ok' );

    $tg2 = Smeagol::Tag->new("capacitat:200");
    ok( defined $tg2 && $tg2->value eq "capacitat:200", 'tag created ok' );

    $tgS->append($tg);
    $tgS->append($tg1);
    ok( $tgS->size == 2, 'tagSet with 2 tags' );

    ok( $r3->tags->size == 1, 'resource tagSet with 1 tags' );
    $r3->tags($tgS);
    ok( $r3->tags->size == 2, 'resource tagSet updated with 2 tags' );

    $r3->tags->append($tg2);
    ok( $r3->tags->size == 3, 'resource tagSet updated with 3 tags' );

    my $values;
    foreach ( $r3->tags->elements ) {
        $values .= " " . $_->value;
    }
    ok( $values        =~ /projector/
            && $values =~ /campus:nord/
            && $values =~ /capacitat:200/
            && $values !~ /aula/,
        'resource tagSet retrieved ok'
    );
}

# Testing UTF-8
{
    my $encoding        = "UTF-8";
    my $description     = decode( $encoding, "àèòéíóúïüçñ" );
    my $info            = decode( $encoding, "äëöâêîôû" );
    my $resource_as_xml = <<"EOF";
<resource>
<description>$description</description>
<agenda>
<booking>
<description>bbbddd</description>
<from>
<year>2009</year><month>4</month><day>16</day>
<hour>19</hour><minute>59</minute><second>0</second>
</from>
<to>
<year>2009</year><month>4</month><day>16</day>
<hour>19</hour><minute>59</minute><second>59</second>
</to>
</booking>
</agenda>
<info>$info</info>
<tags><tag>1111</tag><tag>2222</tag></tags>
</resource>
EOF

    my $r = Smeagol::Resource->newFromXML($resource_as_xml);
    isa_ok( $r, 'Smeagol::Resource' );
    is( $r->description, $description, "description in UTF-8" );
    is( $r->info,        $info,        "info in UTF-8" );
    $r->save;
}

END {
    Smeagol::DataStore->clean();
}
