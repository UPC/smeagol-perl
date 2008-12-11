#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use YAML qw(LoadFile);
use locale;
use Carp qw(confess);

use Client;

=pod

=head1 NAME

Client command line for a standard Smeagol Server

=head1 USAGE

./client.pl [--debug] [--help] [--server=smeagol-gollum.upc.edu] [--port=80] [--command=] ... ""

For details of command option see the pod section in the source client.pl

=head1 REQUIRED ARGUMENTS

=item *

server

Name of the server related of the Smeagol server

=item *

port=80

Standard port is 80

=head1 OPTIONS

=over

=item *

command

Command for connect with the Smeagol system between the Client modul

=item *

help

=item *

debug

=back

=head1 DESCRIPTION

Client command line of the Smeagol system

=head1 BUGS AND LIMITATIONS

Gestió d'errors limitada.

=head1 AUTHOR

cpl-tic-upc smeagol group

=cut

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

#######################################################################
#
# opcions
#

# command-line options (with default values)
my $OPT_SERVER;
my $OPT_PORT = '80';
my $OPT_COMMAND;
my $OPT_PARAM_ID;
my $OPT_PARAM_DES;
my $OPT_PARAM_GRA;
my $OPT_PARAM_FROM;
my $OPT_PARAM_TO;

{
 # parse command-line options
 my $opt_show_help = '';

 my $result = GetOptions(
    "server=s" => \$OPT_SERVER,     # =s means "requires string value"
    "port=i"   => \$OPT_PORT,       # =i means "requires numeric value"
    "command"  => \$OPT_COMMAND,    # =s means "requires string value"
    "id"       => \$OPT_PARAM_ID,   #
    "des"      => \$OPT_PARAM_DES,  #
    "gra"      => \$OPT_PARAM_GRA,  #
    "from"     => \$OPT_PARAM_FROM, #
    "to"       => \$OPT_PARAM_TO,   #
    "help"     => \$opt_show_help
 );

 my ($me) = $0 =~ m{.*/(.*)};
 $USAGE = "$me [--help] [--debug] ".
          "--server=\"http:\/\/localhost\/\"".
          "--port=80".
          "[--command=\" list_resources \| * \"]".
          " \n";

 # Perform action according to options

 if ( !$result ) {
    # Error parsing options. Show errors and quit.
    die $USAGE;
 }
 elsif ($opt_show_help) {
     print $USAGE;
     exit(0);
     # show_help();
 }
}

#######################################################################
#
# switch case of the script.
#

my $result = "";
if      (command  eq "list_resources") {
	$result = Client::list_resources();
} elsif (command  eq "create_resource") {
	$result = Client::create_resource( $OPT_PARAM_ID, $OPT_PARAM_DES, $OPT_PARAM_GRA );
} elsif (command  eq "retrieve_resource") {
	$result = Client::retrieve_resource( $OPT_PARAM_ID );
} elsif (command  eq "delete_resource") {
	$result = Client::delete_resource( $OPT_PARAM_ID );
} elsif (command  eq "update_resource") {
	$result = Client::update_resource( $OPT_PARAM_ID, $OPT_PARAM_DES, $OPT_PARAM_GRA );
} elsif (command  eq "list_bookings_resource") {
	$result = Client::list_bookings_resource( $OPT_PARAM_ID );
} elsif (command  eq "create_booking_resource") {
	$result = Client::create_booking_resource( $OPT_PARAM_ID, $OPT_PARAM_FROM, $OPT_PARAM_TO );
} elsif (command  eq "create_booking") {
	$result = Client::create_booking( $OPT_PARAM_ID, $OPT_PARAM_FROM, $OPT_PARAM_TO );
} elsif (command  eq "retrieve_booking") {
	$result = Client::retrieve_booking( $OPT_PARAM_ID );
} elsif (command  eq "delete_booking") {
	$result = Client::delete_booking( $OPT_PARAM_ID );
} elsif (command  eq "update_booking") {
	$result = Client::update_booking( $OPT_PARAM_ID, $OPT_PARAM_FROM, $OPT_PARAM_TO );
} elsif {
	print "???";
	exit(0);
}

if ( !$result ) {
    # Error parsing options. Show errors and quit.
    die $USAGE;
 }
 else {
     print $result;
     exit(0);
 }


#######################################################################
#
# Program ends here. Auxiliary functions follow.
#

sub _show_help_old_version {
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
