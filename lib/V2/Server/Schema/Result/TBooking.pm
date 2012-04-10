package V2::Server::Schema::Result::TBooking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;
use feature 'switch';

use base 'DBIx::Class::Core';

__PACKAGE__->load_components( "InflateColumn::DateTime", "InflateColumn" );

=head1 NAME

V2::Server::Schema::Result::TBooking

=cut

__PACKAGE__->table("t_booking");

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
    { data_type => "integer", is_auto_increment => 1, is_nullable => 1 },
    "info",
    { data_type => "text", is_nullable => 1, size => 256 },
    "id_resource",
    { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
    "id_event",
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

=head2 id_event

Type: belongs_to

Related object: L<V2::Server::Schema::Result::TEvent>

=cut

__PACKAGE__->belongs_to(
    "id_event",
    "V2::Server::Schema::Result::TEvent",
    { id        => "id_event" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::TResource>

=cut

__PACKAGE__->belongs_to(
    "id_resource",
    "V2::Server::Schema::Result::TResource",
    { id        => "id_resource" },
    { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 t_exceptions

Type: has_many

Related object: L<V2::Server::Schema::Result::TException>

=cut

__PACKAGE__->has_many(
    "t_exceptions",
    "V2::Server::Schema::Result::TException",
    { "foreign.id_booking" => "self.id" },
    { cascade_copy         => 0, cascade_delete => 0 },
);

# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-10 13:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tT60IzggQzPowfJ0YygYMw

__PACKAGE__->has_many(
     "tag_bookings",
     "V2::Server::Schema::Result::TTagBooking",
     { "foreign.id_booking" => "self.id" },
     { cascade_copy       => 0, cascade_delete => 0 },
);

use DateTime;
use DateTime::Duration;
use DateTime::Span;

sub hash_booking {
    my ($self) = @_;
    my @booking;

    @booking = {
	id              		=> $self->id,
        info        			=> $self->info,
        id_resource 		=> $self->id_resource->id,
        id_event    		=> $self->id_event->id,
        dtstart     		=> $self->dtstart->iso8601(),
        dtend       		=> $self->dtend->iso8601(),
        duration    		=> $self->duration,
        until      			=> $self->until->iso8601(),
        frequency   		=> $self->frequency,
        interval    		=> $self->interval,
        by_minute   		=> $self->by_minute,
        by_hour      		=> $self->by_hour,
	by_day       		=> $self->by_day,
        by_month   		=> $self->by_month,
        by_day_month  	=> $self->by_day_month,
        #exrule_list => $self->exrule_list
    };

    return @booking;
}

sub tag_list {
     my ($self) = @_;
     
     my @tags;
     my $tag;
     
     foreach my $tag ( $self->tag_bookings ) {
	  $tag = { id => $tag->id_tag->id };
	  push( @tags, $tag );
     }
     
         return ( \@tags );
}


sub exrule_list {
    my ($self) = @_;

    my @exception;
    my @exceptions;

    foreach my $exception ( $self->t_exceptions ) {
        @exception = { exrule => $exception->exrule };

        push( @exceptions, @exception );
    }

    return ( \@exceptions );
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
