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
my @tags_aux = $c->model('DB::Tag')->all;

my @tags;
my @tag;
foreach (@tags_aux) {
  @tag = {
	id => $_->id  
  };
  push (@tags, @tag);

}

diag(Dumper(\@tags));

done_testing();
