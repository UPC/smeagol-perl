package V2::Server::Schema::ResultSet::Booking;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub overlap {
    my ($self) = @_;

    return 1;
}

1;
