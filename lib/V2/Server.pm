package V2::Server;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Static::Simple
    Unicode
    /;

extends 'Catalyst';

our $NAME    = 'Smeagol Server';
our $VERSION = '2.10';
$VERSION = eval $VERSION;

our $DETAILS = {
    application => $NAME,
    version     => $VERSION,
};

# Configure the application.
#
# Note that settings in v2_server.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'V2::Server',

    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
);

# Start the application
__PACKAGE__->setup();

=head1 NAME

V2::Server - A resource and booking management tool for the greedy

=head1 SYNOPSIS

    script/server.pl

=head1 DESCRIPTION

The L<Universitat PolitE<egrave>cnica de Catalunya|http://www.upc.edu/>
is a large educational organization divided into lots of smaller and
independent units. Each unit deals with its own resources making
usually quite difficult to share them with other units. Plus, each unit
spents many resources in solving the same problems than the other units.
Therefore, the purpose of this project is to establish the grounds
to share resources and feed from the common knowlege available on these
units while trying to find a distributed solution to this particular
problem, the resource and booking management for large organizations.

=head1 AUTHOR

Alex Muntada

See the AUTHORS file for a complete list, this section refers to the
current maintainer only.

=head1 LICENSE

Copyright (C) 2008,2009,2010,2011,2012  Universitat PolitE<egrave>cnica de Catalunya

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
