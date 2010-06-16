package V2::Server::Schema::Result::ResourceTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::ResourceTag

=cut

__PACKAGE__->table("resource_tag");

=head1 ACCESSORS

=head2 resource_id

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: undef

=head2 tag_id

  data_type: TEXT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "resource_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "tag_id",
  {
    data_type => "TEXT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("resource_id", "tag_id");

=head1 RELATIONS

=head2 resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Resource>

=cut

__PACKAGE__->belongs_to(
  "resource",
  "V2::Server::Schema::Result::Resource",
  { id => "resource_id" },
  { join_type => "LEFT" },
);

=head2 tag

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
  "tag",
  "V2::Server::Schema::Result::Tag",
  { id => "tag_id" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-06-16 17:28:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7b1d1syuHZBH1giB2rUDgA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
