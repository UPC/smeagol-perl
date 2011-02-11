package V2::Server::Schema::Result::TResource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn");

=head1 NAME

V2::Server::Schema::Result::TResource

=cut

__PACKAGE__->table("t_resource");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1
  size: 128

=head2 info

  data_type: 'text'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1, size => 128 },
  "info",
  { data_type => "text", is_nullable => 1, size => 256 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 t_bookings

Type: has_many

Related object: L<V2::Server::Schema::Result::TBooking>

=cut

__PACKAGE__->has_many(
  "t_bookings",
  "V2::Server::Schema::Result::TBooking",
  { "foreign.id_resource" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2011-02-10 13:00:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ONo+krYW8mb79nvB14G85Q

__PACKAGE__->has_many(
  "resource_tags",
  "V2::Server::Schema::Result::TResourceTag",
  { "foreign.resource_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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
        my @tag = { id => $tag->tag_id, };
        push( @tags, @tag );
    }

    return ( \@tags );
}

sub book_list {
    my ($self) = @_;

    my @books;
    my @book;

    foreach my $book ( $self->t_bookings ) {
        my @book = { id => $book->id, };
        push( @books, @book );
    }

    return ( \@books );
}

# You can replace this text with custom content, and it will be preserved on regeneration
1;
