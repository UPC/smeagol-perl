package V2::Server::Schema::Result::Tag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn", "Core");
__PACKAGE__->table("tag");
__PACKAGE__->add_columns(
  "id",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 64 },
  "description",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 256 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "resource_tags",
  "V2::Server::Schema::Result::ResourceTag",
  { "foreign.tag_id" => "self.id" },
);
__PACKAGE__->has_many(
  "tag_events",
  "V2::Server::Schema::Result::TagEvent",
  { "foreign.id_tag" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-10-14 10:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2m+kU1Psq24iPaw+ogFlNg
sub hash_tag {
      my ($self) = @_;
      
      my @tag = {
	    id          => $self->id,
	    description => $self->description,
	    # events      => $self->tag_events->id,
	    # resources   => $self->resource_tags->id
      };
      return \@tag;
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
