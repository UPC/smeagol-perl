package V2::Server::Schema::Result::TException;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;
use feature 'switch';

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn" );

=head1 NAME

V2::Server::Schema::Result::TException

=cut

__PACKAGE__->table("t_exception");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1

=head2 id_booking

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 dtstart

  data_type: 'datetime'
  is_nullable: 1

=head2 dtend

  data_type: 'datetime'
  is_nullable: 1

=head2 duration

  data_type: 'duration'
  is_nullable: 1

=head2 frequency

  data_type: 'text'
  is_nullable: 1

=head2 interval

  data_type: 'integer'
  is_nullable: 1

=head2 until

  data_type: 'datetime'
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
    { data_type => "integer", is_auto_increment => 1 },
    "id_booking",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "dtstart",
    { data_type => "datetime", is_nullable => 1 },
    "dtend",
    { data_type => "datetime", is_nullable => 1 },
    "duration",
    { data_type => "duration", is_nullable => 1 },
    "frequency",
    { data_type => "text", is_nullable => 1 },
    "interval",
    { data_type => "integer", is_nullable => 1 },
    "until",
    { data_type => "datetime", is_nullable => 1 },
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

=head2 id_booking

Type: belongs_to

Related object: L<V2::Server::Schema::Result::TBooking>

=cut

__PACKAGE__->belongs_to(
    "id_booking",
    "V2::Server::Schema::Result::TBooking",
    { id        => "id_booking" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-10 13:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JD8ZVuFrITtvGIXgqAdl5Q
use DateTime;
use DateTime::Duration;
use DateTime::Span;
use Date::ICal;

sub as_hash {
    my ($self) = @_;
    my $until = Date::ICal->new(
        year   => $self->until->year,
        month  => $self->until->month,
        day    => $self->until->day,
        hour   => $self->until->hour,
        minute => $self->until->minute,
    );

    my @exception = (
        id         => $self->id,
        id_booking => $self->id_booking->id,
        dtstart    => $self->dtstart->iso8601(),
        dtend      => $self->dtend->iso8601(),
        duration   => $self->duration,
        until      => $self->until->iso8601(),
        frequency  => $self->frequency,
        interval   => $self->interval,
        byminute   => $self->by_minute,
        byhour     => $self->by_hour,
    );

    my %dispatch = (
        daily => [
        ],

        weekly => [
            byday  => $self->by_day,
        ],

        monthly => [
            bymonth    => $self->by_month,
            bymonthday => $self->by_day_month,
        ],

        yearly => [
            byday      => $self->by_day,
            bymonth    => $self->by_month,
            bymonthday => $self->by_day_month,
        ],
    );

    my $freq = exists $dispatch{ $self->frequency } ? $self->frequency : 'yearly';
    push @exception, @{ $dispatch{$freq} }, exrule => $self->exrule;

    return { @exception };
}

sub exrule {
    my ($self) = @_;

    my $until = Date::ICal->new(
        year   => $self->until->year,
        month  => $self->until->month,
        day    => $self->until->day,
        hour   => $self->until->hour,
        minute => $self->until->minute,
    );

    my %dispatch = (
        daily => sub {
            'FREQ=DAILY;INTERVAL='
                . uc( $self->interval )
                . ';UNTIL='
                . uc( $until->ical )
        },
        weekly => sub {
            'FREQ=WEEKLY;INTERVAL='
                . uc( $self->interval )
                . ';BYDAY='
                . uc( $self->by_day )
                . ';UNTIL='
                . uc( $until->ical )
        },
        monthly => sub {
            'FREQ=MONTHLY;INTERVAL='
                . uc( $self->interval )
                . ';BYMONTHDAY='
                . $self->by_day_month
                . ';UNTIL='
                . uc( $until->ical )
        },
        yearly => sub {
            'FREQ=YEARLY;INTERVAL='
                . uc( $self->interval )
                . ';BYDAY='
                . uc( $self->by_day )
                . ';BYMONTH='
                . $self->by_month
                . ';BYMONTHDAY='
                . $self->by_day_month
                . ';UNTIL='
                . uc( $until->ical )
        },
    );

    my $freq = exists $dispatch { $self->frequency } ? $self->frequency : 'yearly';

    return $dispatch{$freq}->();
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
