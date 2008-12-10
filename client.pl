#!/usr/bin/perl

### #!/usr/local/web/perl/bin/perl -w

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

./client.pl [--debug] [--help] [--server=trantor.upc.edu] [--url="http://localhost/smeagol/ETSETB/"] [--port=80] ""

=head1 REQUIRED ARGUMENTS

=head1 OPTIONS

=over

=item *

server

Name of the server related of the Smeagol server

=item *

url

Based in standard URI

=item *

port=80

Standard port is 80

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
my $OPT_URL;
my $OPT_PORT = '80';
my $opt_COMMAND;

{
 # parse command-line options
 my $opt_show_help = '';

 my $result = GetOptions(
    "server"   => \$OPT_SERVER,     # =s means "requires string value"
    "url=s"    => \$OPT_URL,        # =s means "requires string value"
    "port=i"   => \$OPT_PORT,       # =i means "requires numeric value"
    "command=s" => \$OPT_COMMAND,    # =s means "requires string value"
    "help"     => \$OPT_show_help
 );

 my ($me) = $0 =~ m{.*/(.*)};
 $USAGE = "$me [--help] [--debug] ".
          "[--server=\"???\"]".
          "[--url=\"http:\/\/...\/\"]".
          "[--port=80]".
          "[--command=\" GET \| POST \| PUT \| DELETE \"]".
          " \n";

 if ($help) {
 }

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

#######################################################################
#
# Program ends here. Auxiliary functions follow.
#

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
