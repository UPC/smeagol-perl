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
my @resources_aux = $c->model('DB::Resource')->all;

my @resources;
my $resource;
foreach (@resources_aux) {
  $resource = $_->id;
  push (@resources, $resource);

}

diag(Dumper(\@resources));

done_testing();
