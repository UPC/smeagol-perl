package V2::Server::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
	TEMPLATE_EXTENSION => '.tt',
	INCLUDE_PATH       => [
		V2::Server->path_to( 'root', 'templates' ),
	],
);

=head1 NAME

V2::Server::View::TT - TT View for V2::Server

=head1 DESCRIPTION

TT View for V2::Server.

=head1 SEE ALSO

L<V2::Server>

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
