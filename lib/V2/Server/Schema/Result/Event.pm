package V2::Server::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Event

=cut

__PACKAGE__->table("event");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=head2 info

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: undef

=head2 description

  data_type: TEXT
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

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "info",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
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

=head2 tag_events

Type: has_many

Related object: L<V2::Server::Schema::Result::TagEvent>

=cut

__PACKAGE__->has_many(
  "tag_events",
  "V2::Server::Schema::Result::TagEvent",
  { "foreign.id_event" => "self.id" },
);

=head2 booking_s

Type: has_many

Related object: L<V2::Server::Schema::Result::Booking>

=cut

__PACKAGE__->has_many(
  "booking",
  "V2::Server::Schema::Result::Booking",
  { "foreign.id_event" => "self.id" },
);

# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-11 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mpI3x2qk+IJqNAA2RGn3RQ

# You can replace this text with custom content, and it will be preserved on regeneration
1;
