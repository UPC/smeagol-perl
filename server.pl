#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use Server;

my $version   = "Smeagol server v0.1";
my $copyright = "Copyright (C) 2008 Universitat Politècnica de Catalunya";

####################################################
# License messages (using the GPLv3 as an example) #
####################################################

# Long license message
my $license_full = <<END;
$version
$copyright

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
END

# Short license message
my $license_short = <<END;
$version
$copyright

This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
END

# command-line options (with default values)
my $opt_port         = 8000;
my $opt_host         = '';
my $opt_background   = '';
my $opt_log_file     = '';     # option not yet implemented
my $opt_error_file   = '';     # option not yet implemented
my $opt_debug        = '';
my $opt_show_version = '';
my $opt_show_license = '';
my $opt_show_help    = '';

# parse command-line options

my $result = GetOptions(
    "port=i"     => \$opt_port,           # =i means "requires numeric value"
    "host=s"     => \$opt_host,           # no modifier; means "flag value"
    "log=s"      => \$opt_log_file,       # =s means "requires string value"
    "error=s"    => \$opt_error_file,
    "debug"      => \$opt_debug,
    "background" => \$opt_background,
    "version"    => \$opt_show_version,
    "license"    => \$opt_show_license,
    "help"       => \$opt_show_help
);

# Perform action according to options

if ( !$result ) {

    # Error parsing options. Show errors and quit.
}
elsif ($opt_show_help) {
    show_help();
}
elsif ($opt_show_license) {
    show_license();
}
elsif ($opt_show_version) {
    show_version();
}
else {
    launch_server(
        $opt_port,     $opt_host,       $opt_background,
        $opt_log_file, $opt_error_file, $opt_debug
    );
}

# Program ends here. Auxiliary functions follow.

sub show_help {
    print $license_short;
    print <<END;

Usage: $0 [options]

General options:

    --port <number>   Listen on port <number> (default: $opt_port)
    --host <address>  Address to bind to (default: all interfaces)             
    --background      Run as server (go to background)
    --log <file>      Log messages to file <file> (default: stdout)
                        (This option is not yet implemented)
    --errors <file>   Log errors to file <file> (default: stdout)
                        (This option is not yet implemented)
    --debug           Show debug messages in log (see --log)
    --version         Show program version
    --license         Show program license
    --help            Show this message

END
}

sub show_license {
    print $license_full;
}

sub show_version {
    print $license_short;
}

sub launch_server {
    my ( $port, $host, $background, $log_file, $error_file, $debug ) = @_;

    if ($debug) {
        print "$version\n\n";
        print "Entering debug mode.\n";
        print "Listening on port $port.\n";
        print "Binding to " . ( $host or "all interfaces" ) . ".\n";
        print "Log messages to "
            . ( $log_file or "stdout" )
            . " (not implemented).\n";
        print "Log errors to "
            . ( $error_file or "stdout" )
            . " (not implemented).\n";
    }

    my $s = Server->new($port);

    $s->host($host);

    if ($background) {
        my $pid = $s->background;
        print "Going background (PID $pid).\n";
    }
    else {
        print "Running...\n" if $debug;
        $s->run;
    }

}

