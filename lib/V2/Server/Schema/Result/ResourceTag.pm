package V2::Server::Schema::Result::ResourceTag;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

<<<<<<< .working
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");
=======
__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn",
    "TimeStamp" );
>>>>>>> .merge-right.r1154

=head1 NAME

V2::Server::Schema::Result::ResourceTag

=cut

__PACKAGE__->table("resource_tag");

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
  size: 20

=cut

__PACKAGE__->add_columns(
    "resource_id",
    {   data_type         => "integer",
        is_auto_increment => 1,
        is_foreign_key    => 1,
        is_nullable       => 1,
    },
    "tag_id",
    {   data_type      => "text",
        is_foreign_key => 1,
        is_nullable    => 1,
        size           => 20
    },
);
__PACKAGE__->set_primary_key( "resource_id", "tag_id" );

=head1 RELATIONS

=head2 tag

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Tag>

=cut

__PACKAGE__->belongs_to(
    "tag",
    "V2::Server::Schema::Result::Tag",
    { id        => "tag_id" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Resource>

=cut

__PACKAGE__->belongs_to(
    "resource",
    "V2::Server::Schema::Result::Resource",
    { id        => "resource_id" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-22 16:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T8mHcEIGrenypnxWDxubMg

<<<<<<< .working
# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-11 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZXVZnTTYd+3XXEL+HEPxnw


=======
>>>>>>> .merge-right.r1154
# You can replace this text with custom content, and it will be preserved on regeneration
1;
