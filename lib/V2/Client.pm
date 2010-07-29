package V2::Client;

use strict;
use warnings;

use DateTime;
use LWP::UserAgent;
use Carp;
use Data::Dumper;

use Moose;

has 'url' => (
    is       => 'rw',
    required => 1,
    default  => sub {
        my $self = shift;
        my %args = @_;
        return $args{url};
    }
);
has 'ua' => (
    isa      => 'LWP::UserAgent',
    is       => 'rw',
    required => 1,
    default  => sub {
        my $self = shift;
        my $ua   = LWP::UserAgent->new();
        $ua->agent("SmeagolClient/0.1 ");
        return $ua;
    }
);

1;
