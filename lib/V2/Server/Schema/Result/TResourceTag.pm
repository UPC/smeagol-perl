package V2::Server::Schema::Result::TResourceTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn");

=head1 NAME

V2::Server::Schema::Result::TResourceTag

=cut

__PACKAGE__->table("t_resource_tag");

=head1 ACCESSORS

=head2 resource_id

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 1

=head2 tag_id

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "resource_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_foreign_key    => 1,
    is_nullable       => 1,
  },
  "tag_id",
  { data_type => "text", is_foreign_key => 1, is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("resource_id", "tag_id");


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-10 13:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:s6KrEh8/rf6MzDrlKL9yPA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
