package V2::Server::Schema::Result::Resource;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Resource

=cut

__PACKAGE__->table("resources");

=head1 ACCESSORS

=head2 id

  data_type: INTEGER
  default_value: undef
  is_nullable: 1
  size: undef

=head2 description

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: undef

=head2 info

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: undef

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INTEGER",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "description",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "info",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 resource_tags

Type: has_many

Related object: L<V2::Server::Schema::Result::ResourceTag>

=cut

__PACKAGE__->has_many(
  "resource_tags",
  "V2::Server::Schema::Result::ResourceTag",
  { "foreign.resource_id" => "self.id" },
);

=head2 booking_s

Type: has_many

Related object: L<V2::Server::Schema::Result::Booking>

=cut

__PACKAGE__->has_many(
  "booking",
  "V2::Server::Schema::Result::Booking",
  { "foreign.id_resource" => "self.id" },
);

=head2 booking_rs

Type: has_many

Related object: L<V2::Server::Schema::Result::BookingR>

=cut

__PACKAGE__->has_many(
  "booking_rs",
  "V2::Server::Schema::Result::BookingR",
  { "foreign.id_resource" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-05-11 17:00:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i0wIfiASaDeBdqtSChYFaw
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

# You can replace this text with custom content, and it will be preserved on regeneration
1;
