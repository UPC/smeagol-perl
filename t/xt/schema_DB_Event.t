use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN { 
    use_ok 'Catalyst::Test', 'V2::Server'; 
    use_ok 'DBICx::TestDatabase';
}

ok my ($res, $c) = ctx_request('/'), 'context object';  # make sure we got the context object...

my $schema = DBICx::TestDatabase->new('V2::Server::Schema');
my @events_aux = $c->model('DB::Event')->all;

my @events;
my @event;
foreach (@events_aux) {
      @event = {
	    $_->id
      };
  push (@events, @event);

}

diag(Dumper(\@events));

done_testing();
