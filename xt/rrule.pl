use strict;
use warnings;

use DateTime::Format::ICal;
use DateTime::Event::ICal;
use Data::ICal::Entry::Event;
use Data::ICal;
use Data::Dumper;

my $dt = DateTime::Format::ICal->parse_datetime( '20101215T125900Z' );
my $ical = 'DateTime::Format::ICal';

print $dt."\n";

my $string = "RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=1SU;";
my $dt2 = DateTime::Format::ICal->parse_recurrence( 
  recurrence => $string, 
  dtstart    => $ical->parse_datetime('20101201T090000' ),
  dtend      => $ical->parse_datetime('20121201T090000' )
);

my @byday = ("fr");
my $set_aux = DateTime::Event::ICal->recur(
  dtstart => DateTime->new(    year => 2010,
			       month => 12,
			       day => 17,
			       hour => 9,
			       minute => 0),
  until => DateTime->new(    year => 2010,
			      month => 12,
			      day => 17,
			      hour => 10,
			      minute => 0),
  freq =>    "weekly",
  interval => 1,
  byminute => 20,
  byhour => 10,
  byday => \@byday,
  bymonth => 12,
  bymonthday => 17
);
my $vevent = Data::ICal::Entry::Event->new();
$vevent->add_properties(
  uid => 1,
  summary => "Booking #1",
  dtstart => Date::ICal->new(
    year => 2010,
    month => 12,
    day => 17,
    hour => 9,
    minute => 0,
  )->ical,
  dtend => Date::ICal->new(
    year => 2010,
    month => 12,
    day => 17,
    hour => 10,
    minute => 0,
  )->ical,
  until => Date::ICal->new(
    year => 2010,
    month => 12,
    day => 17,
    hour => 10,
    minute => 0,
  )->ical,
  duration => $_->{duration},
  rrule => $set_aux->{as_ical}->[1]
  
);


print "\n".Dumper($dt2)."\n";

1;
