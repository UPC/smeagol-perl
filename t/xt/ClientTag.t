#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;
use JSON::Any;
use Test::MockModule;
use HTTP::Status qw(:constants :is status_message);
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(
        V2::Client::Tag
    );
}

my $serverPort = 3000;
my $server     = "http://localhost:$serverPort";
my $module     = 'V2::Client::Tag';

my @emptyTagList;

#NEW
{
    can_ok( $module, 'new' );
    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );

    my $id = 'socUnTag';

    $sct->id($id);
    is( $sct->id, $id, 'id() setter and getter' );
}

# Testing Client::Tag->list() with empty result list
{
    my $EXPECTED_TAGS = 0; # expected number of tags returned by mocked server
    my $JSON_TAG_LIST = '[]';    # tag list to mock

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($JSON_TAG_LIST);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );

    my @list = $sct->list();
    ok( @list == $EXPECTED_TAGS, 'number of elements in empty tag list' );
}

# Testing Client::Tag->list() with non-empty result list
{
    my $EXPECTED_TAGS = 2; # expected number of tags returned by mocked server
    my $JSON_TAG_LIST
        = '[ {"id": "tag1"},{"id": "tag2"} ]';    # tag list to mock

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($JSON_TAG_LIST);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );
    my @list = $sct->list();
    ok( @list == $EXPECTED_TAGS, 'number of elements in non-empty tag list' );

    my $tag1 = $list[0];
    my $tag2 = $list[1];
    isa_ok( $tag1, $module ) || diag explain $tag1;
    isa_ok( $tag2, $module ) || diag explain $tag2;
    is( $tag1->id, 'tag1', 'first element is tag1' );
    is( $tag2->id, 'tag2', 'second element is tag2' );
}

#GET
{
    my $tagId = "tagForGetTests";

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'get' );

    my @list = $sct->list();
    my $tag = $list[0] if ( defined $list[0] );

    my $r = $sct->get( $tag->id() );

    isa_ok( $r, $module );
    is( $r->id(), $tag->id, "id() should return '" . $r->id() . "'" );
}

# Testing Client::Tag->create()
{
    my $tagId = 'tagForCreateTests';

    my $EXPECTED_BEFORE_CREATION = '[ {"id": "dummy"} ]';
    my $EXPECTED_AFTER_CREATION
        = '[ {"id": "dummy"}, {"id": "' . $tagId . '"} ]';
    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');

    # mock for "get" before tag creation
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($EXPECTED_BEFORE_CREATION);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'create' );

    my @listBefore = $sct->list();
    is( scalar(@listBefore), 1, 'right number of tags before creation' );

    $lwpUserAgent->mock(
        'post',
        sub {
            my $res = HTTP::Response->new();
            $res->header( 'Location' => "$server/tag/$tagId" );
            $res->code(HTTP_CREATED);
            $res;
        }
    );

    my $tag = $sct->create( id => $tagId );
    isa_ok( $tag, $module );

    # mock for "get" after tag creation
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($EXPECTED_AFTER_CREATION);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my @listAfter = $sct->list();

    is( $tag->id(),
        $listAfter[ ( scalar @listAfter ) - 1 ]->id(),
        "id() should return '" . $tag->id() . "'"
    );

    is( scalar(@listAfter), scalar(@listBefore) + 1, "added one tag" );
}

=pod

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
=cut
