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

#ok( request('/booking')->is_success, 'Request should succeed' );
ok( my $response_post = request POST '/booking',
    [
      dtstart => '2010-10-21T09:00',
      dtend => '2010-10-21T10:30',
      id_event => '1',
      id_resource => '1',
      frequency => '',
      interval => '',
      until => '',
      by_day => '',
     ],
    HTTP::Headers->new(Accept => 'application/json')
   
);

diag "Resposta: ".$response_post->content;

done_testing();