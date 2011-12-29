package V2::Server::Schema::Result::TTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn" );

=head1 NAME

V2::Server::Schema::Result::TTag

=cut

__PACKAGE__->table("t_tag");

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

=head2 t_tag_events

Type: has_many

Related object: L<V2::Server::Schema::Result::TTagEvent>

=cut

__PACKAGE__->has_many(
    "t_tag_events",
    "V2::Server::Schema::Result::TTagEvent",
    { "foreign.id_tag" => "self.id" },
    { cascade_copy     => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-10 13:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QZV1/yQTHg1xNhBI5dJh9A

# You can replace this text with custom content, and it will be preserved on regeneration
1;
