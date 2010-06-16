package V2::Server::Schema::Result::Booking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Booking

=cut

__PACKAGE__->table("booking");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_auto_increment: 1
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

=head2 frequency

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=head2 interval

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=head2 duration

  data_type: (empty string)
  default_value: undef
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

=head2 per_minuts

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=head2 per_hores

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=head2 per_dies

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=head2 per_mesos

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=head2 per_dia_mes

  data_type: (empty string)
  default_value: undef
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_auto_increment => 1,
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
  "frequency",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
  "interval",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
  "duration",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
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
  "per_minuts",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
  "per_hores",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
  "per_dies",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
  "per_mesos",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
  "per_dia_mes",
  { data_type => "", default_value => undef, is_nullable => 1, size => undef },
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


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-06-16 17:28:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XY0yxIN0wyIsPetlckMGTQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
