#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 22;
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

# new(), setters and getters
{
    can_ok( $module, 'new' );
    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'list' );

    my $id          = 'socUnTag';
    my $description = 'Sóc una descripció';

    $sct->id($id);

    #$sct->description($description);
    is( $sct->id, $id, 'id() setter and getter' );

    #is( $sct->description, $description, 'description() setter and getter' );
}

# Testing Client::Tag->list() with empty result list
{
    my $EXPECTED_TAGS = 0; # expected number of tags returned by mocked server
    my $JSON_TAG_LIST = '[]';    # an empty list, in JSON

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
    ok( scalar @list == $EXPECTED_TAGS,
        'number of elements in empty tag list'
    );
}

# Testing Client::Tag->list() with non-empty result list
{
    my ( $id1, $desc1 ) = ( 'tag1', 'desc1' );
    my ( $id2, $desc2 ) = ( 'tag2', 'desc2' );
    my $EXPECTED_TAGS = 2; # expected number of tags returned by mocked server
    my $JSON_TAG_LIST = '[ 
             {"id": "' . $id1 . '", "description" : "' . $desc1 . '"},
             {"id": "' . $id2 . '", "description" : "' . $desc2 . '"} 
           ]';             # tag list to use when mocking

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

    my ( $tag1, $tag2 ) = @list;
    isa_ok( $tag1, $module ) || diag explain $tag1;
    isa_ok( $tag2, $module ) || diag explain $tag2;

    #is( ( $tag1->id, $tag1->description ), ( $id1, $desc1 ), 'tag1 found' );
    #is( ( $tag2->id, $tag2->description ), ( $id2, $desc2 ), 'tag2 found' );
}

# Testing Client::Tag->get()
# TODO: additional test for get(), with non-existent tag, needed
{
    my ( $id, $desc ) = ( "myId", "myDescription" );
    my $JSON_TAG = '{ "id" : "' . $id . '", "description" : "' . $desc . '"}';

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($JSON_TAG);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $sct = $module->new( url => $server );
    isa_ok( $sct, $module );
    can_ok( $sct, 'get' );

    my $tag = $sct->get($id);

    isa_ok( $tag, $module );

    #is( ( $tag->id, $tag->description ), ( $id, $desc ), "tag found" );
}

# Testing Client::Tag->create()
# TODO: tests for create() when tag already exists, invalid id/description, etc
{
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

# Client::Tag->delete()
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

