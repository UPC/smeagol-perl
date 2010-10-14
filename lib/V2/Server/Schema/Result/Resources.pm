package V2::Server::Schema::Result::Resources;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "InflateColumn", "Core");
__PACKAGE__->table("resources");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 128 },
  "info",
  { data_type => "TEXT", default_value => undef, is_nullable => 1, size => 256 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "resource_tags",
  "V2::Server::Schema::Result::ResourceTag",
  { "foreign.resource_id" => "self.id" },
);
__PACKAGE__->has_many(
  "bookings",
  "V2::Server::Schema::Result::Booking",
  { "foreign.id_resource" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-10-14 10:30:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0qptKZefrPlliu4ZpfN8hg
sub get_resources {
      my ($self) = @_;
      
      my @resource;
      my @resources;
      
      foreach ($self) {
	    @resource = {
		  id          => $_->id,
		  description => $_->description,
		  info        => $_->info,
		  tags        => $_->tag_list,
		  bookings    => $_->book_list
	    };
	    push( @resources, @resource );
      }
      
      return @resources;
      
}

sub tag_list {
      my ($self) = @_;
      
      my @tags;
      my @tag;
      
      foreach my $tag ( $self->resource_tags ) {
	    my @tag = { id => $tag->tag_id->id, };
	    push( @tags, @tag );
      }
      
      return ( \@tags );
}

sub book_list {
      my ($self) = @_;
      
      my @books;
      my @book;
      
      foreach my $book ( $self->bookings ) {
	    my @book = { id => $book->id, };
	    push( @books, @book );
      }
      
      return ( \@books );
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
