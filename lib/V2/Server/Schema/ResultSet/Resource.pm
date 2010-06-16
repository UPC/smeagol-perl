package V2::Server::Schema::ResultSet::Resource;

use strict;
use warnings;

use base 'DBIx::Class::ResultSet';

sub tag_count {
    my ($self) = @_;

    return $self->resource_tag->count;
}

sub tag_list {
    my ($self) = @_;

    my @tags;
    my @tag;

    foreach my $tag ($self->resource_tags) {
      my @tag = {
	id => $tag->tag_id,
      };
	push(@tags, @tag);
    }

    return (\@tags);
}

1;