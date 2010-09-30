#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::MockModule;
use JSON::Any;
use HTTP::Status qw(:constants :is status_message);
use Data::Dumper;

BEGIN {
    use_ok($_) for qw(
        V2::Client::Resource
    );
}

my $serverPort = 3000;
my $server     = "http://localhost:$serverPort";
my $module     = 'V2::Client::Resource';

# Client::Resource->new(), setters and getters
{
    can_ok( $module, 'new' );
    my $scr = $module->new( url => $server );
    isa_ok( $scr, $module );
    can_ok( $scr, 'list' );
    can_ok( $scr, 'create' );
    can_ok( $scr, 'get' );
    can_ok( $scr, 'update' );
    can_ok( $scr, 'delete' );
    can_ok( $scr, 'tag' );
    can_ok( $scr, 'unTag' );
    can_ok( $scr, 'findTags' );
    can_ok( $scr, 'findEvents' );
    can_ok( $scr, 'findBookings' );

    my $id   = $server . '/resource/23';
    my $desc = 'Sóc una descripció';
    my $info = 'Sóc una info';

    $scr->id($id);
    $scr->info($info);

    is( $scr->id,   $id,   'id() setter and getter' );
    is( $scr->info, $info, 'info() setter and getter' );

    # TODO: To avoid script abort due to missing description() method,
    # the description() tests are temporally encapsulated in an SKIP block
SKIP: {
        skip "desc() setter/getter must be renamed to description()", 1
            if !can_ok( $scr, 'description' );

        $scr->description($desc);
        is( $scr->description, $desc, 'desc() setter and getter' );
    }

}

# Client::Resource->list() with empty result list
{
    my $RESOURCE_COUNT = 0;       # expected no. of resources in server
    my $JSON_LIST      = '[]';    # JSON resource list returned by server

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($JSON_LIST);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $scr = $module->new( url => $server );
    my @resources = $scr->list();

    is( scalar @resources,
        $RESOURCE_COUNT, "right number of resources in empty list" );

}

# Client::Resource->list() with non-empty result list
{
    my $RESOURCE_COUNT = 2;    # expected no. of resources in server
    my ( $id1, $desc1, $info1 ) = ( "$server/resource/1", "desc1", "info1" );
    my ( $id2, $desc2, $info2 ) = ( "$server/resource/2", "desc2", "info2" );
    my $resource1 = { id => $id1, description => $desc1, info => $info1 };
    my $resource2 = { id => $id2, description => $desc2, info => $info2 };

    my $j = JSON::Any->new;
    my $JSON_LIST = $j->to_json( [ $resource1, $resource2 ] )
        ;                      # JSON resource list returned by server

    #print Dumper($JSON_LIST);

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $res = HTTP::Response->new();
            $res->content($JSON_LIST);
            $res->code(HTTP_OK);
            $res;
        }
    );

    my $scr = $module->new( url => $server );
    my @resources = $scr->list();

    is( scalar @resources,
        $RESOURCE_COUNT, "right number of resources in non-empty list" );

    cmp_deeply(
        $resources[0],
        methods( id => $id1, description => $desc1, info => $info1 ),
        "resource1 found"
    );
    cmp_deeply(
        $resources[1],
        methods( id => $id2, description => $desc2, info => $info2 ),
        "resource1 found"
    );
}

# Client::Resource->create()
{
    my ( $desc, $info ) = ( 'foo', 'bar' );
    my $id          = 20;                       # whatever
    my $resourceUrl = "$server/resource/$id";
    my $jsonStr;    # JSON representation of the resource

    my $scr = $module->new( url => $server );

    # the "Client::Resource->create" method is composed by two
    # calls to the server:
    #  1) a POST call, which creates the resource and gets the ID
    #     via "Location" header.
    #  2) a GET call to the location obtained previously, to get the
    #     JSON representation of the resource.
    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'post',
        sub {
            my ( $self, $parameters ) = @_;
            my $res = HTTP::Response->new();
            $jsonStr = JSON::Any->objToJson(
                {   description => $parameters->{description},
                    info        => $parameters->{info}
                }
            );
            $res->header( 'Location' => $resourceUrl );
            $res->code(HTTP_CREATED);
            $res;
        }
    );
    $lwpUserAgent->mock(
        'get',
        sub {
            my $url = shift;
            my $res = HTTP::Response->new();
            if ( $url eq $resourceUrl ) {
                $res->code(HTTP_OK);
                $res->content($jsonStr);
            }
            else {
                $res->code(HTTP_NOT_FOUND);
            }
            $res;
        }
    );

    my $r = $scr->create( description => $desc, info => $info );

    isa_ok( $r, $module );

    cmp_deeply(
        $r,
        methods( description => $desc, info => $info ),
        "resource created successfully"
    );
}

# Client::Resource->get(id)
{
    my $id          = 20;                       # whatever
    my $resourceUrl = "$server/resource/$id";
    my ( $desc, $info ) = ( 'foo', 'bar' );

    my $scr = $module->new( url => $server );

    my $lwpUserAgent = new Test::MockModule('LWP::UserAgent');
    $lwpUserAgent->mock(
        'get',
        sub {
            my $url = shift;
            my $res = HTTP::Response->new();
            if ( $url eq $resourceUrl ) {
                $res->code(HTTP_OK);
                $res->content(
                    JSON::Any->objectToJson(
                        { description => $desc, info => $info }
                    )
                );
            }
            else {
                $res->code(HTTP_NOT_FOUND);
            }
            $res;
        }
    );

    my $r = $scr->get($resourceUrl);

    isa_ok( $r, $module );

    cmp_deeply(
        $r,
        methods( description => $desc, info => $info, id => $resourceUrl ),
        "resource retrieved successfully"
    );
}

# Client::Resource->update(id, description, info)
{
    my ( $desc,    $info )    = ( 'foo',    'bar' );
    my ( $newdesc, $newinfo ) = ( 'newfoo', 'newbar' );
    my $resourceUrl = "$server/resource/$id";

    my $scr = $module->new( url => $server );

    # create a new resource first
    my $r = $scr->create( description => $desc, info => $info );

    cmp_deeply(
        $r,
        methods( description => $desc, info => $info, id => $resourceUrl ),
        "resource created successfully"
    );

    # update the resource
    $r->update( description => $newdesc, info => $newinfo );

    cmp_deeply(
        $r,
        methods( description => $desc, info => $info, id => $resourceUrl ),
        "resource retrieved successfully"
    );

}

done_testing();

