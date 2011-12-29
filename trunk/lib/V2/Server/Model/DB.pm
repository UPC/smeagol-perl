package V2::Server::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

my $db = $ENV{TESTING_DB} ||= 'smeagol.db';

__PACKAGE__->config(
    schema_class => 'V2::Server::Schema',

    connect_info => {
        dsn      => "dbi:SQLite:$db",
        user     => '',
        password => '',
	on_connect_call => 'use_foreign_keys',
    }
);

=head1 NAME

V2::Server::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<V2::Server>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<V2::Server::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.41

=head1 AUTHOR

jamoros

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
