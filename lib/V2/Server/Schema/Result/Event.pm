package V2::Server::Schema::Result::Event;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn", "Core");
__PACKAGE__->table("event");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "info",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 256 },
  "description",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 128 },
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
__PACKAGE__->has_many(
  "tag_events",
  "V2::Server::Schema::Result::TagEvent",
  { "foreign.id_event" => "self.id" },
);
__PACKAGE__->has_many(
  "bookings",
  "V2::Server::Schema::Result::Booking",
  { "foreign.id_event" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-10-14 10:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MYSJvX3kIX1N+9QFptYKBQ


sub hash_event {
      my ($self) = @_;
      
      my @event = {
	    id          => $self->id,
	    info        => $self->info,
	    description => $self->description,
	    starts      => $self->starts->iso8601(),
	    ends        => $self->ends->iso8601(),
	    tags        => $self->tag_list,
	    bookings    => $self->booking_list
      };
      
      return @event;
}

sub tag_list {
      my ($self) = @_;
      
      my @tags;
      my @tag;
      
      foreach my $tag ( $self->tag_events ) {
	    @tag = { id => $tag->id_tag->id };
	    push( @tags, @tag );
      }
      
      return ( \@tags );
}

sub booking_list {
      my ($self) = @_;
      
      my @bookings;
      my @booking;
      
      foreach my $booking ( $self->bookings ) {
	    @booking = { id => $booking->id };
	    push( @bookings, @booking );
      }
      
      return ( \@bookings );
}
# You can replace this text with custom content, and it will be preserved on regeneration
1;
