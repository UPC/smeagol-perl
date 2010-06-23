package V2::Server::Schema::ResultSet::Resource;

use strict;
use warnings;
use Data::Dumper;

use base 'DBIx::Class::ResultSet';

sub get_resources {
  my ($self) = @_;

  my @resource;
  my @resources;

  foreach ($self) {
    @resource = {
      id => $_->id,
      description => $_->description,
      info => $_->info,
      tags => $_->tag_list,
	    };
    push (@resources, @resource);
  }

  return @resources;

}

1;