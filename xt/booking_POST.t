use strict;
use warnings;

use Test::More;
use Data::Dumper;
use HTTP::Request;
use HTTP::Request::Common;
require LWP::UserAgent;
use JSON::Any;
use DateTime;
use DateTime::Duration;

BEGIN { use_ok 'Catalyst::Test', 'V2::Server' }
BEGIN { use_ok 'V2::Server::Controller::Booking' }

my $dt1 = DateTime->now->truncate( to => 'minute' );
my $dtstart = $dt1->clone->add( days => 0, hours => 0 );
my $dtend   = $dt1->clone->add( days => 0, hours => 2 );

ok( my $response_post = request POST '/booking',
    [   id_event    => "1",
        id_resource => "1",
        dtstart     => $dtstart,
        dtend       => $dtend,
        freq        => 'daily',
        interval    => 3,
        until       => $dtend->clone->add( days => 30 ),
        by_minute   => $dtstart->minute,
        by_hour     => $dtstart->hour,
        by_day      => 'mo,tu,we,th,fr',
        by_month    => $dtstart->month,
        by_day_month =>
            "1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31"
    ],
    HTTP::Headers->new( Accept => 'application/json' )

);

diag "Resposta: " . $response_post->content;

# ok( $response_post = request POST '/booking',
#     [
#       dtstart => '2010-10-21T9:00',
#       dtend => '2010-10-21T10:30',
#       id_event => '2',
#       id_resource => '2',
#       frequency => 'weekly',
#       interval => '1',
#       until => '',
#       by_day => 'mo,tu,we,th,fr'
#      ],
#     HTTP::Headers->new(Accept => 'application/json')
#
# );
#
# diag "Resposta: ".$response_post->content;

done_testing();
