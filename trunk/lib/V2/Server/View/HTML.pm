package V2::Server::View::HTML;

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    {   INCLUDE_PATH => [
            V2::Server->path_to( 'root', 'src' ),
            V2::Server->path_to( 'root', 'lib' ),
            V2::Server->path_to( 'root', 'templates' ),
        ],
        PRE_PROCESS  => 'config/main',
        WRAPPER      => 'site/wrapper',
        ERROR        => 'error.tt2',
        TIMER        => 0,
        render_die   => 1,
        CONTENT_TYPE => 'text/html',

    }
);

=head1 NAME

V2::Server::View::HTML - Catalyst TTSite View

=head1 SYNOPSIS

See L<V2::Server>

=head1 DESCRIPTION

Catalyst TTSite View.

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

