package V2::Server::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Tag

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 resource_tags

Type: has_many

Related object: L<V2::Server::Schema::Result::ResourceTag>

=cut

__PACKAGE__->has_many(
  "resource_tags",
  "V2::Server::Schema::Result::ResourceTag",
  { "foreign.tag_id" => "self.id" },
);

=head2 tag_events

Type: has_many

Related object: L<V2::Server::Schema::Result::TagEvent>

=cut

__PACKAGE__->has_many(
  "tag_events",
  "V2::Server::Schema::Result::TagEvent",
  { "foreign.id_tag" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-06-16 17:28:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rg2x2VHfNqT5pR6qPyU2Xw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
