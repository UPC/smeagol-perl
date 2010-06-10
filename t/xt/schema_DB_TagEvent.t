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
my @event_tags_aux = $c->model('DB::EventTag')->all;

my @event_tags;
my @event_tag;
foreach (@event_tags_aux) {
  @event_tag = {
	id => $_->id
  };
  push (@event_tags, @event_tag);

}

diag(Dumper(\@event_tags));

done_testing();
