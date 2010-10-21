package V2::Server::Schema::Result::Booking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "TimeStamp",
    "InflateColumn" );

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

=head2 dtstart

  data_type: 'datetime'
  is_nullable: 1

=head2 dtend

  data_type: 'datetime'
  is_nullable: 1

=head2 until

  data_type: 'datetime'
  is_nullable: 1

=head2 frequency

  data_type: 'text'
  is_nullable: 1

=head2 interval

  data_type: 'integer'
  is_nullable: 1

=head2 duration

  data_type: 'duration'
  is_nullable: 1

=head2 by_minute

  data_type: 'integer'
  is_nullable: 1

=head2 by_hour

  data_type: 'integer'
  is_nullable: 1

=head2 by_day

  data_type: 'text'
  is_nullable: 1

=head2 by_month

  data_type: 'text'
  is_nullable: 1

=head2 by_day_month

  data_type: 'integer'
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
    "until",
    {   data_type                 => "datetime",
        is_nullable               => 1,
        datetime_undef_if_invalid => 1
    },
    "frequency",
    { data_type => "text", is_nullable => 1 },
    "interval",
    { data_type => "integer", is_nullable => 1 },
    "duration",
    { data_type => "datetime:duration", is_nullable => 1 },
    "by_minute",
    { data_type => "integer", is_nullable => 1 },
    "by_hour",
    { data_type => "integer", is_nullable => 1 },
    "by_day",
    { data_type => "text", is_nullable => 1 },
    "by_month",
    { data_type => "text", is_nullable => 1 },
    "by_day_month",
    { data_type => "integer", is_nullable => 1 },
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
    { id => "id_event" },
);

=head2 id_resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Resources>

=cut

__PACKAGE__->belongs_to(
    "id_resource",
    "V2::Server::Schema::Result::Resources",
    { id => "id_resource" },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-10-15 15:48:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7kVGJeM2G+qM/nXRN5Xy4A
use DateTime;
use DateTime::Span;

sub hash_booking {
    my ($self) = @_;
    my @booking;

    @booking = {
        id           => $self->id,
        id_resource  => $self->id_resource->id,
        id_event     => $self->id_event->id,
        dtstart      => $self->dtstart->iso8601(),
        dtend        => $self->dtend->iso8601(),
        until        => $self->until,
        frequency    => $self->frequency,
        interval     => $self->interval,
        duration     => $self->duration,
        by_minute    => $self->by_minute,
        by_hour      => $self->by_hour,
        by_day       => $self->by_day,
        by_month     => $self->by_month,
        by_day_month => $self->by_day_month
    };
    return @booking;
}

sub overlap {
    my ($self) = @_;
    my $overlap = 0;
    return $overlap;
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
