package V2::Server::Schema::Result::Booking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Booking

=cut

__PACKAGE__->table("booking_s");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=head2 id_resource

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: undef

=head2 id_event

  data_type: INTEGER
  default_value: undef
  is_foreign_key: 1
  is_nullable: 1
  size: undef

=head2 starts

  data_type: DATETIME
  default_value: undef
  is_nullable: 1
  size: undef

=head2 ends

  data_type: DATETIME
  default_value: undef
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "id_resource",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "id_event",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 1,
    size => undef,
  },
  "starts",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "ends",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Resource>

=cut

__PACKAGE__->belongs_to(
  "id_resource",
  "V2::Server::Schema::Result::Resource",
  { id => "id_resource" },
  { join_type => "LEFT" },
);

=head2 id_event

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Event>

=cut

__PACKAGE__->belongs_to(
  "id_event",
  "V2::Server::Schema::Result::Event",
  { id => "id_event" },
  { join_type => "LEFT" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-11 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jKHpneqSVqu/3B57e6mGoQ
sub overlap {
      my ($self) = @_;
      
      return 1;
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
