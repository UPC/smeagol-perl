package V2::Server::Schema::Result::ResourceTag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn", "Core");
__PACKAGE__->table("resource_tag");
__PACKAGE__->add_columns(
  "resource_id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "tag_id",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("resource_id", "tag_id");
__PACKAGE__->belongs_to(
  "resource_id",
  "V2::Server::Schema::Result::Resources",
  { id => "resource_id" },
);
__PACKAGE__->belongs_to(
  "tag_id",
  "V2::Server::Schema::Result::Tag",
  { id => "tag_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-10-14 10:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PZiV7H83IxOEmCaouvKpWg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
