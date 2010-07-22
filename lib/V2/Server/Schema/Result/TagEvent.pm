package V2::Server::Schema::Result::TagEvent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn",
    "TimeStamp" );

=head1 NAME

V2::Server::Schema::Result::TagEvent

=cut

__PACKAGE__->table("tag_event");

=head1 ACCESSORS

=head2 id_tag

  data_type: 'text'
  is_foreign_key: 1
  is_nullable: 1
  size: 20

=head2 id_event

  data_type: 'integer'
  is_auto_increment: 1
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id_tag",
    {   data_type      => "text",
        is_foreign_key => 1,
        is_nullable    => 1,
        size           => 20
    },
    "id_event",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_foreign_key    => 1,
        is_nullable       => 1,
    },
);
__PACKAGE__->set_primary_key( "id_tag", "id_event" );

=head1 RELATIONS

=head2 id_event

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Event>

=cut

__PACKAGE__->belongs_to(
    "id_event",
    "V2::Server::Schema::Result::Event",
    { id        => "id_event" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_tag

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
    "id_tag",
    "V2::Server::Schema::Result::Tag",
    { id        => "id_tag" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-22 16:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IlalDVwNgB5he8mASJTqEA

# You can replace this text with custom content, and it will be preserved on regeneration
1;
