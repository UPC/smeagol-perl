package V2::Server::View::JSON;

use strict;
use base 'Catalyst::View::JSON';

=head1 NAME

V2::Server::View::JSON - Catalyst JSON View

=head1 SYNOPSIS

See L<V2::Server>

=head1 DESCRIPTION

Catalyst JSON View.

=cut

__PACKAGE__->config(
    expose_stash => 'content',
    allow_nonref => 1,
);

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
