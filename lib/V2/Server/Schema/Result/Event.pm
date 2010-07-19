package V2::Server::Schema::Result::Event;

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

V2::Server::Schema::Result::Event

=cut

__PACKAGE__->table("event");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
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
<<<<<<< .working
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
=======
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
>>>>>>> .merge-right.r1154
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
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 booking_s

Type: has_many

Related object: L<V2::Server::Schema::Result::Booking>

=cut

__PACKAGE__->has_many(
<<<<<<< .working
  "booking_s",
  "V2::Server::Schema::Result::Booking",
  { "foreign.id_event" => "self.id" },
=======
    "bookings",
    "V2::Server::Schema::Result::Booking",
    { "foreign.id_event" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
>>>>>>> .merge-right.r1154
);

<<<<<<< .working
=head2 booking_rs
=======
# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-22 16:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MuzaCKudC5m6kOh8npTYUw
>>>>>>> .merge-right.r1154

<<<<<<< .working
Type: has_many
=======
sub hash_event {
    my ($self) = @_;
>>>>>>> .merge-right.r1154

<<<<<<< .working
Related object: L<V2::Server::Schema::Result::BookingR>
=======
    my @event = {
        id          => $self->id,
        info        => $self->info,
        description => $self->description,
        starts      => $self->starts->iso8601(),
        ends        => $self->ends->iso8601(),
    };
>>>>>>> .merge-right.r1154

<<<<<<< .working
=cut

__PACKAGE__->has_many(
  "booking_rs",
  "V2::Server::Schema::Result::BookingR",
  { "foreign.id_event" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-11 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mpI3x2qk+IJqNAA2RGn3RQ

=======
    return \@event;
}

>>>>>>> .merge-right.r1154
# You can replace this text with custom content, and it will be preserved on regeneration
1;
