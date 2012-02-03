package V2::Server::Schema::Result::TEvent;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn" );

=head1 NAME

V2::Server::Schema::Result::TEvent

=cut

__PACKAGE__->table("t_event");

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

=head2 t_tag_events

Type: has_many

Related object: L<V2::Server::Schema::Result::TTagEvent>

=cut

__PACKAGE__->has_many(
    "t_tag_events",
    "V2::Server::Schema::Result::TTagEvent",
    { "foreign.id_event" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

=head2 t_bookings

Type: has_many

Related object: L<V2::Server::Schema::Result::TBooking>

=cut

__PACKAGE__->has_many(
    "t_bookings",
    "V2::Server::Schema::Result::TBooking",
    { "foreign.id_event" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-10 13:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aNC7MABaa/QlI6cH7Xofeg

__PACKAGE__->has_many(
    "tag_events",
    "V2::Server::Schema::Result::TTagEvent",
    { "foreign.id_event" => "self.id" },
    { cascade_copy       => 0, cascade_delete => 0 },
);

sub hash_event {
    my ($self) = @_;

    my @event = {
        id          => $self->id,
        info        => $self->info,
        description => $self->description,
        starts      => $self->starts->iso8601(),
        ends        => $self->ends->iso8601(),
        #tags        => $self->tag_list,
        #bookings    => $self->booking_list,
    };

    return @event;
}

sub tag_list {
    my ($self) = @_;

    my @tags;
    my $tag;

    foreach my $tag ( $self->tag_events ) {
        $tag = { id => $tag->id_tag->id };
        push( @tags, $tag );
    }

    return ( \@tags );
}

sub booking_list {
    my ($self) = @_;

    my @bookings;
    my @booking;

    foreach my $booking ( $self->t_bookings ) {
        @booking = { id => $booking->id };
        push( @bookings, @booking );
    }

    return ( \@bookings );
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;

