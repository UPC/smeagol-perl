#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use Client;

=pod

Documentacio of the Comand Line Client for the Smeagol Server powered CPL-TIC-UPC

sub list_resources () -> ( @_ ) __tq__ $_[0] = num_status & $_[1] = "xml_result"
sub create_resource ( $id, $des, $gra ) -> num_status
sub retrieve_resource ( $id ) -> ( @_ ) __tq__ $_[0] = num_status & $_[1] = "xml_result"
sub delete_resource ( $id ) -> num_status
sub update_resource ( $id, $des, $gra ) -> num_status
sub list_bookings_resource ( $id  ) -> ( @_ ) __tq__ $_[0] = num_status & $_[1] = "xml_result"
sub create_booking_resource ( $id, @from, @to ) -> num_status
sub create_booking ( $id, @from, @to ) -> num_status
sub retrieve_booking ( $id  ) -> ( @_ ) __tq__ $_[0] = num_status & $_[1] = "xml_result"
sub delete_booking ( $id ) -> num_status
sub update_booking ( $id, @from, @to ) -> num_status

:· tipus of parameters ::
$id   = "identificador del objecte"
$des  = "descripció del objecte"
$gra  = "granularity"
@from = " data in format "
@to   = " data in format "

=cut

# command-line options (with default values)
my $opt_server;
my $opt_url;
my $opt_port = '80';
my $opt_comand;
my $opt_show_help = '';

# parse command-line options
my $result = GetOptions(
    "server=s" => \$opt_server,     # =s means "requires string value"
    "url=s"    => \$opt_url,        # =s means "requires string value"
    "port=i"   => \$opt_port,       # =i means "requires numeric value"
    "comand=s" => \$opt_comand,     # =s means "requires string value"
    "help"     => \$opt_show_help
);

# Perform action according to options

if ( !$result ) {

    # Error parsing options. Show errors and quit.
}
elsif ($opt_show_help) {
    show_help();
}
else {

    # Client::_client_call
}

# Program ends here. Auxiliary functions follow.

sub show_help {
    print <<END;
Usage: $0 [options]

General options:
    --server <string> 
    --url <string>
    --port <number>   Listen on port <number> (default: $opt_port)
    --comand <exemples>
    --help            Show this message

END
}
