#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use Test::Deep;
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

note "Tests for $module->new, getters and setters";

# new(), setters and getters
{
    can_ok( $module, 'new' );
    my $sct = new_ok( $module => [ 'url', $server ] );

    my $id          = 'socUnTag';
    my $description = 'Sóc una descripció';

    $sct->id($id);
    $sct->description($description);

    cmp_deeply(
        $sct,
        methods( id => $id, description => $description ),
        "setters and getters ok"
    );

    note "$module->_fullPath => ", $sct->_fullPath;

}

sub testClientTagList {
    my %args         = @_;
    my $mocked       = defined $args{wantMock};
    my $expected     = $args{expectedTags};
    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');

    if ($mocked) {
        my $tags;
        for ( my $i = 1; $i <= $expected; $i++ ) {
            $tags
                .= '{ "id" : "id' 
                . $i
                . '", "description" : "desc'
                . $i . '" }';
            $tags .= ', ' if ( $i < $expected );
        }

        my $JSON_TAG_LIST = "[ $tags ]";

        $lwpUserAgent->mock(
            'get',
            sub {
                my $res = HTTP::Response->new();
                $res->content($JSON_TAG_LIST);
                $res->code(HTTP_OK);
                $res;
            }
        );
    }

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );

    my @list = $sct->list();
    is( scalar @list,
        $expected,
        "number of elements ("
            . ( scalar @list )
            . ") in tag list (wantMock = "
            . ( $mocked ? 'yes' : 'no' ) . ")"
    );

    if ($mocked) {
        $lwpUserAgent->unmock_all();
    }
}

note "Tests for $module->list";

testClientTagList( wantMock => 1, expectedTags => 3 );
testClientTagList( expectedTags => 8 );

note "Testing $module->get()";

# TODO: additional test for get(), with non-existent tag, needed

sub testClientTagGet {
    my %args   = @_;
    my $mocked = defined $args{wantMock};
    my ( $id, $desc ) = ( "myId", "myDescription" );
    my $JSON_TAG = '{ "id" : "' . $id . '", "description" : "' . $desc . '"}';
    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');

    if ($mocked) {
        $lwpUserAgent->mock(
            'get',
            sub {
                my $res = HTTP::Response->new();
                $res->content($JSON_TAG);
                $res->code(HTTP_OK);
                $res;
            }
        );
    }

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'get' );

    my $tag = $sct->get( id => $id );

    isa_ok( $tag, $module );

    cmp_deeply(
        $tag,
        methods( id => $id, description => $desc ),
        "tag attributes fully retrieved"
    );

    if ($mocked) {
        $lwpUserAgent->unmock_all();
    }
}

testClientTagGet( wantMock => 1 );
testClientTagGet();

note "Testing Client::Tag->create()";

#TODO: tests for create() when tag already exists, invalid id/description, etc

TODO: {
    my ( $tagId, $tagDesc )
        = ( 'tagForCreateTests', 'tagForCreateTests description' );

    my $EXPECTED_BEFORE_CREATION = '[ ]';
    my $EXPECTED_AFTER_CREATION
        = '[ {"id": "' . $tagId . '", "description" : "' . $tagDesc . '"} ]';
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
    is( scalar(@listBefore), 0, 'right number of tags before creation' );

    $lwpUserAgent->mock(
        'post',
        sub {
            my $res = HTTP::Response->new();
            $res->header( 'Location' => "$server/tag/$tagId" );
            $res->code(HTTP_CREATED);
            $res;
        }
    );

    my $tag = $sct->create( id => $tagId, description => $tagDesc );
    isa_ok( $tag, $module );

    is( $tag->id(),          $tagId,   "id() should be $tagId" );
    is( $tag->description(), $tagDesc, "description() should be $tagDesc" );

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
    is( scalar(@listAfter), scalar(@listBefore) + 1, "added one tag" );

    my $created = $listAfter[0];

    is( $tag, $created, "new tag found in server tag list" );

}

note "Testing $module->update()";

#UPDATE
{
    my $tagId      = "tagId";
    my $descBefore = "descBefore";
    my $descAfter  = "descAfterAfter";

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'update' );

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');

    # TODO: There is no method named 'put' in LWP::UserAgent. We should
    #       extend that module and implement that method.
    # The server must return the URL for the updated tag
    $lwpUserAgent->mock(
        'put',
        sub {
            my $self = shift;
            my $res  = HTTP::Response->new();
            $res->header( 'Location' => $server . '/tag/' . $tagId );
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $tag = $sct->update( id => $tagId, description => $descAfter );
    isa_ok( $tag, $module );

    is( $tag->id,          $tagId,     "id should should not change" );
    is( $tag->description, $descAfter, "description has been updated" );
}

note "Testing Client::Tag->delete()";

TODO: {

    my $tagId = "id";

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'delete',
        sub {
            my $res = HTTP::Response->new();
            $res->header( 'Location' => $server . '/tag/' . $tagId );
        }
    );

    my @list = $sct->list();
    foreach (@list) {
        my $tag = $sct->delete( $_->id );
        isa_ok( $tag, $module );
        is( $tag->{message},
            'Tag successfully deleted',
            "id should have deleted " . $_->id
        );
    }

    $sct->delete($tagId);

}

