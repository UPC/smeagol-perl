package V2::Server::Schema::Result::Tag;

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

V2::Server::Schema::Result::Tag

=cut

__PACKAGE__->table("tag");

=head1 ACCESSORS

=head2 id

  data_type: 'text'
  is_nullable: 1
  size: 20

=cut

__PACKAGE__->add_columns( "id",
    { data_type => "text", is_nullable => 1, size => 20 } );
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

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-22 16:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6v59uQuR/ng7fnDPEoqYMQ

<<<<<<< .working
# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-11 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bW1ZUz8lmRvehVU2pF7uuw


=======
>>>>>>> .merge-right.r1154
# You can replace this text with custom content, and it will be preserved on regeneration
1;
