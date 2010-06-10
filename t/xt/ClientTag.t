#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 8;
use JSON::Any;
use Test::MockModule;

BEGIN {
    use_ok($_) for qw(
        V2::Client::Tag
    );
}

my $serverPort = 8080;
my $server     = "http://localhost:$serverPort";
my $module     = 'V2::Client::Tag';

my @emptyTagList;

#NEW
{
    can_ok( $module, 'new' );
    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );
}

#LIST
{
    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res           = HTTP::Response->new();
            my $emptyJsonList = '[]';
            $res->content($emptyJsonList);
            $res;
        }
    );

    my $sct = $module->new( url => $server );

    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );

    my @list = $sct->list();
    isa_ok( $list[0], $module ) if ( defined $list[0] );

}

#CREATE
TODO: {
    local $TODO = "Not yet mocked";

    my ($name) = ("CN");

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'create' );

    my @list1 = $sct->list();

    my $tag = $sct->create( name => $name );
    isa_ok( $tag, $module );

    my @list2 = $sct->list();

    is( $tag->id(),
        $list2[ ( scalar @list2 ) - 1 ]->id(),
        "id() should return '" . $tag->id() . "'"
    );

    is( scalar(@list1) + 1, scalar(@list2), "added one tag" );
}

#GET
TODO: {
    local $TODO = "Not yet mocked";

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'get' );

    my @list = $sct->list();
    my $tag = $list[0] if ( defined $list[0] );

    my $r = $sct->get( $tag->id() );

    isa_ok( $r, $module );
    is( $r->id(), $tag->id, "id() should return '" . $r->id() . "'" );
}

#UPDATE
TODO: {
    local $TODO = "Not yet mocked";

    my ($name)  = ("IIIIIIIIIIIIIII");
    my ($name2) = ("iiiiiiiiiiiiii");

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'update' );

    my $tag = $sct->create( name => $name );
    isa_ok( $tag, $module );
    my $tag2 = $sct->update( id => $tag->id, name => $name2 );
    is( $tag2->id(), $tag->id(), "id should return " . $tag->id() );
}

#DELETE
TODO: {
    local $TODO = "Not yet mocked";

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );

    my @list = $sct->list();
    foreach (@list) {
        my $tag = $sct->delete( $_->id );
        isa_ok( $tag, $module );
        is( $tag->{message},
            'Tag successfully deleted',
            "id should have deleted " . $_->id
        );
    }

}
