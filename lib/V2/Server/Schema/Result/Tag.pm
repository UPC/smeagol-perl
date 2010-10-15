package V2::Server::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn");

=head1 NAME

V2::Server::Schema::Result::Tag

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 1
  size: 64

=head2 description

  data_type: 'text'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "text", is_nullable => 1, size => 64 },
  "description",
  { data_type => "text", is_nullable => 1, size => 256 },
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
  {},
);

=head2 tag_events

Type: has_many

Related object: L<V2::Server::Schema::Result::TagEvent>

=cut

__PACKAGE__->has_many(
  "tag_events",
  "V2::Server::Schema::Result::TagEvent",
  { "foreign.id_tag" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-10-15 15:48:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Y7KCc0jp9oDuL/uuOlx4ag
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
