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
my @resource_tags_aux = $c->model('DB::ResourceTag')->all;

my @resource_tags;
my $resource_tag;
foreach (@resource_tags_aux) {
  $resource_tag = $_->id;
  push (@resource_tags, $resource_tag);

}

diag(Dumper(\@resource_tags));

done_testing();
