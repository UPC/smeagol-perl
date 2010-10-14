package V2::Server::Schema::Result::TagEvent;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn", "Core");
__PACKAGE__->table("tag_event");
__PACKAGE__->add_columns(
  "id_tag",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 64 },
  "id_event",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id_tag", "id_event");
__PACKAGE__->belongs_to(
  "id_tag",
  "V2::Server::Schema::Result::Tag",
  { id => "id_tag" },
);
__PACKAGE__->belongs_to(
  "id_event",
  "V2::Server::Schema::Result::Event",
  { id => "id_event" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-10-14 10:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iYBn7PkCVOLgBWBYfchKXw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
