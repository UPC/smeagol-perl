use strict;
use warnings;
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok 'Catalyst::Test', 'V2::Server';
    use_ok 'DBICx::TestDatabase';
}

ok my ( $res, $c ) = ctx_request('/'),
    'context object';    # make sure we got the context object...

my $schema   = DBICx::TestDatabase->new('V2::Server::Schema');
my @tags_aux = $c->model('DB::Tag')->all;

my @tags;
my @tag;
foreach (@tags_aux) {
    @tag = { id => $_->id };
    push( @tags, @tag );

}

diag( Dumper( \@tags ) );

diag("############################################################## \n");
diag("Create tag \n");
diag("############################################################## \n");

ok my $new_tag = $c->model('DB::Tag')->find_or_new();

ok $new_tag->id('Test');
ok( $new_tag->insert, 'tag creation should succeed' );

my $id_new = $new_tag->id;
diag( "New tag ID: " . $id_new );

unless ( my $tag_edit = $c->model('DB::Tag')->find( { id => $id_new } ) ) {
    diag("Tag creation failed");
}
else {
    diag("Tag creation ok");
}

diag("############################################################## \n");
diag(" Edition Tag \n");
diag("############################################################## \n");
my $tag_edit = $c->model('DB::Tag')->find( { id => $id_new } );
ok $tag_edit->id('Test (edited)');
ok( $tag_edit->update, 'tag edition should succeed' );

diag("############################################################## \n");
diag(" Checking tag edition \n");
diag("############################################################## \n");

ok my $tag_check = $c->model('DB::Tag')->find( { id => $tag_edit->id } );

diag( "\nId tag: " . $tag_check->id . " and should be " . $tag_edit->id );
diag("There is something wrong") unless $tag_check->id eq $tag_edit->id;

diag("############################################################## \n");
diag(" Delete tag edition \n");
diag("############################################################## \n");

$tag_check->delete;

unless ( my $tag_check = $c->model('DB::Tag')->find( { id => $id_new } ) ) {
    diag("Delete test ok \n");
}
else {
    diag("Delete test failed \n");
}

done_testing();
