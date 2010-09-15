package V2::Server::Schema::Result::Tag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn",
    "TimeStamp" );

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
    "id",          { data_type => "text", is_nullable => 1, size => 64 },
    "description", { data_type => "text", is_nullable => 1, size => 256 },
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
    { cascade_copy     => 0, cascade_delete => 0 },
);

=head2 tag_events

Type: has_many

Related object: L<V2::Server::Schema::Result::TagEvent>

=cut

__PACKAGE__->has_many(
    "tag_events",
    "V2::Server::Schema::Result::TagEvent",
    { "foreign.id_tag" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-07-20 18:40:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2PycvPGaD5pMgith4ksFcg

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
