package V2::Server::Schema::Result::Booking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn",
    "TimeStamp" );

=head1 NAME

V2::Server::Schema::Result::Booking

=cut

__PACKAGE__->table("booking");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 id_resource

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 id_event

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 starts

  data_type: 'datetime'
  is_nullable: 1

=head2 ends

  data_type: 'datetime'
  is_nullable: 1

=head2 frequency

  data_type: (empty string)
  is_nullable: 1

=head2 interval

  data_type: (empty string)
  is_nullable: 1

=head2 duration

  data_type: (empty string)
  is_nullable: 1

=head2 per_minuts

  data_type: (empty string)
  is_nullable: 1

=head2 per_hores

  data_type: (empty string)
  is_nullable: 1

=head2 per_dies

  data_type: (empty string)
  is_nullable: 1

=head2 per_mesos

  data_type: (empty string)
  is_nullable: 1

=head2 per_dia_mes

  data_type: (empty string)
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 1 },
    "id_resource",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "id_event",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "dtstart",
    { data_type => "datetime", is_nullable => 1 },
    "dtend",
    { data_type => "datetime", is_nullable => 1 },
    "frequency",
    { data_type => "", is_nullable => 1 },
    "interval",
    { data_type => "", is_nullable => 1 },
    "duration",
    { data_type => "", is_nullable => 1 },
    "by_minute",
    { data_type => "", is_nullable => 1 },
    "by_hour",
    { data_type => "", is_nullable => 1 },
    "by_day",
    { data_type => "", is_nullable => 1 },
    "by_month",
    { data_type => "", is_nullable => 1 },
    "by_day_month",
    { data_type => "", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

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

=head2 id_resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Resource>

=cut

__PACKAGE__->belongs_to(
    "id_resource",
    "V2::Server::Schema::Result::Resource",
    { id        => "id_resource" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-07-20 18:39:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:805sw5JLWdOKhwL7WSDTTg

use DateTime::Span;

sub hash_booking {
    my ($self) = @_;

    my @booking = {
        id          => $self->id,
        id_resource => $self->id_resource->id,
        id_event    => $self->id_event->id,
        dtstart      => $self->dtstart->iso8601(),
        dtend        => $self->dtend->iso8601(),
    };
    return @booking;
}

sub overlap {
    my ( $self, $current_set ) = @_;
    my $overlap         = 0;
    my $old_booking_set = DateTime::Span->from_datetimes(
        (   start => $self->dtstart,
            end   => $self->dtend->clone->subtract( seconds => 1 )
        )
    );

    if ( $old_booking_set->intersects($current_set) ) {
        $overlap = 1;
    }

    return $overlap;
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
