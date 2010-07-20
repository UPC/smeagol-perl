package V2::Server::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn");

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
  size: 256

=head2 description

  data_type: 'text'
  is_nullable: 1
  size: 128

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
  { data_type => "text", is_nullable => 1, size => 256 },
  "description",
  { data_type => "text", is_nullable => 1, size => 128 },
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


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-07-20 18:40:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rZ/kpSSl5CEI5XSpU1FOUw

sub hash_event {
    my ($self) = @_;

    my @event = {
        id          => $self->id,
        info        => $self->info,
        description => $self->description,
        starts      => $self->starts->iso8601(),
        ends        => $self->ends->iso8601(),
    };
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
