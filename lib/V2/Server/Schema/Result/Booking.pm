package V2::Server::Schema::Result::Booking;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "InflateColumn", "TimeStamp");

=head1 NAME

V2::Server::Schema::Result::Booking

=cut

__PACKAGE__->table("booking");

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

=head2 starts

  data_type: 'datetime'
  is_nullable: 1

=head2 ends

  data_type: 'datetime'
  is_nullable: 1

=head2 frequency

  data_type: (empty string)
  is_nullable: 1

=head2 interval

  data_type: (empty string)
  is_nullable: 1

=head2 duration

  data_type: (empty string)
  is_nullable: 1

=head2 per_minuts

  data_type: (empty string)
  is_nullable: 1

=head2 per_hores

  data_type: (empty string)
  is_nullable: 1

=head2 per_dies

  data_type: (empty string)
  is_nullable: 1

=head2 per_mesos

  data_type: (empty string)
  is_nullable: 1

=head2 per_dia_mes

  data_type: (empty string)
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 1 },
  "id_resource",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "id_event",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "starts",
  { data_type => "datetime", is_nullable => 1 },
  "ends",
  { data_type => "datetime", is_nullable => 1 },
  "frequency",
  { data_type => "", is_nullable => 1 },
  "interval",
  { data_type => "", is_nullable => 1 },
  "duration",
  { data_type => "", is_nullable => 1 },
  "per_minuts",
  { data_type => "", is_nullable => 1 },
  "per_hores",
  { data_type => "", is_nullable => 1 },
  "per_dies",
  { data_type => "", is_nullable => 1 },
  "per_mesos",
  { data_type => "", is_nullable => 1 },
  "per_dia_mes",
  { data_type => "", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 id_event

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Event>

=cut

__PACKAGE__->belongs_to(
  "id_event",
  "V2::Server::Schema::Result::Event",
  { id => "id_event" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 id_resource

Type: belongs_to

Related object: L<V2::Server::Schema::Result::Resource>

=cut

__PACKAGE__->belongs_to(
  "id_resource",
  "V2::Server::Schema::Result::Resource",
  { id => "id_resource" },
  { join_type => "LEFT", on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07000 @ 2010-06-22 16:34:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C6gkav+hj8AJTN8BF2iYdg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
