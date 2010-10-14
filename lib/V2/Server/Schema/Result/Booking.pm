package V2::Server::Schema::Result::Booking;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn", "Core");
__PACKAGE__->table("booking");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "id_resource",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "id_event",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dtstart",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "dtend",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "until",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "frequency",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "interval",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "duration",
  {
    data_type => "DURATION",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "by_minute",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "by_hour",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "by_day",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "by_month",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "by_day_month",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "id_resource",
  "V2::Server::Schema::Result::Resources",
  { id => "id_resource" },
);
__PACKAGE__->belongs_to(
  "id_event",
  "V2::Server::Schema::Result::Event",
  { id => "id_event" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-10-14 10:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Z1pgMjizD80k/u/sfT+P+w
use DateTime;
use DateTime::Span;

sub hash_booking {
      my ($self) = @_;
      
      my $dtend = $self->dtend;
      
      if ($dtend) {
	    my $res;
	    ($dtend,$res) = split(' ',$dtend);
	    my ($year,$month,$day) = split('-',$dtend);
	    
	    $dtend = DateTime->new(
		  year => $year,
		  month => $month,
		  day => $day
		  );
	    $dtend = $dtend->iso8601();
      }else{
	    $dtend = undef;
      }
      
      my @booking = {
	    id          => $self->id,
	    id_resource => $self->id_resource->id,
	    id_event    => $self->id_event->id,
	    dtstart      => $self->dtstart->iso8601(),
	    dtend        => $dtend,
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
