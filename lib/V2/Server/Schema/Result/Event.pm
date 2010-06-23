package V2::Server::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Event

=cut

__PACKAGE__->table("event");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 info

  data_type: 'text'
  is_nullable: 1
  size: 50

=head2 description

  data_type: 'text'
  is_nullable: 1
  size: 20

=head2 starts

  data_type: 'datetime'
  is_nullable: 1

=head2 ends

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 1 },
  "info",
  { data_type => "text", is_nullable => 1, size => 50 },
  "description",
  { data_type => "text", is_nullable => 1, size => 20 },
  "starts",
  { data_type => "datetime", is_nullable => 1 },
  "ends",
  { data_type => "datetime", is_nullable => 1 },
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
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bookings

Type: has_many

Related object: L<V2::Server::Schema::Result::Booking>

=cut

__PACKAGE__->has_many(
  "bookings",
  "V2::Server::Schema::Result::Booking",
  { "foreign.id_event" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-22 16:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MuzaCKudC5m6kOh8npTYUw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
