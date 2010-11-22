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

ok( my $response_post = request POST '/booking',
    [
#       dtstart => '2010-12-1T9:00',
#       dtend => '2010-12-1T10:30',
       id_event => '1',
       id_resource => '1',
#       frequency => '',
#       interval => '',
#       until => '2010-12-1T11:00',
    freq => 'yearly',
    dtstart => $dt1,
    dtend => $dt1->clone->add( hours => 2 ),
    until => $dt1->clone->add( years => 2 ),
     ],
    HTTP::Headers->new(Accept => 'application/json')
   
);

diag "Resposta: ".$response_post->content;

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