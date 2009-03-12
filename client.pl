#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use locale;
use Carp qw(confess);

use Client;

use Data::Dumper;

=pod

=head1 NAME

Client $OPT_COMMAND line for a standard Smeagol Server

=head1 USAGE

./client.pl [--debug] [--help] [--server=smeagol-gollum.upc.edu] [--port=80] [--$OPT_COMMAND=] ... ""

For details of $OPT_COMMAND option see the pod section in the source client.pl

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

$OPT_COMMAND

Command for connect with the Smeagol system between the Client modul

=item *

help

=item *

debug

=back

=head1 DESCRIPTION

Client $OPT_COMMAND line of the Smeagol system

=head1 BUGS AND LIMITATIONS

Gestió d'errors limitada.
## sub list_bookings_resource ( $id  ) -> ( @_ ) __tq__ $_[0] = num_status & $_[1] = "xml_result"
## sub create_booking_resource ( $id, @from, @to ) -> num_status

=head1 AUTHOR

cpl-tic-upc smeagol group

=cut

=pod

Documentacio of the Comand Line Client for the Smeagol Server powered CPL-TIC-UPC

sub listResources () -> ( @_ )

sub createResource ( $id, $des, $gra ) -> $id
sub getResource ( $id ) -> $resource
sub delResource ( $id ) -> $id
sub updateResource ( $id, $des, $gra ) -> $id

sub createBooking ( $id, @from, @to ) -> $id
sub getBooking ( $id  ) -> ( $id, @from, @to )
sub delBooking ( $id ) -> $id
sub updateBooking ( $id, $des, $gra ) -> $id

sub createAgenda ( $id ) -> $id
sub getAgenda ( $id ) -> $id
sub delAgenda ( $id ) -> $id
sub updateAgenda ( $id ) -> $id

:· tipus of parameters ::
$id   = "identificador del objecte"
$des  = "descripció del objecte"
$gra  = "granularity"
@from = " data in format dd/mm/aass hh:mm:ss "
@to   = " data in format dd/mm/aass hh:mm:ss "## sub list_bookings_resource ( $id  ) -> ( @_ ) __tq__ $_[0] = num_status & $_[1] = "xml_result"
## sub create_booking_resource ( $id, @from, @to ) -> num_status


=cut

#######################################################################
#
# opcions
#

my $USAGE;

# $OPT_COMMAND-line options (with default values)
my $OPT_SERVER = "http://localhost";
my $OPT_PORT   = '8000';
my $OPT_COMMAND;
my $OPT_PARAM_ID;
my $OPT_PARAM_ID_B;
my $OPT_PARAM_DES;
my $OPT_PARAM_GRA;
my $OPT_PARAM_FROM;
my $OPT_PARAM_TO;
my $OPT_PARAM_R;

# parse command-line options

my $opt_show_help = '';

my $options = GetOptions(
    "server=s" => \$OPT_SERVER,        # server
    "port=i"   => \$OPT_PORT,          # port
    "c=s"      => \$OPT_COMMAND,       # command
    "id=i"     => \$OPT_PARAM_ID,      #
    "idB=i"    => \$OPT_PARAM_ID_B,    #
    "des=s"    => \$OPT_PARAM_DES,     #
    "gra=s"    => \$OPT_PARAM_GRA,     #
    "from=s"   => \$OPT_PARAM_FROM,    #
    "to=s"     => \$OPT_PARAM_TO,      #
    "r"        => \$OPT_PARAM_R,       # recursive
    "help"     => \$opt_show_help

        # =i means "requires numeric value"
        # =s means "requires string value"
);

my ($me) = $0 =~ m{.*/(.*)};
$me = $0 if !( defined($me) );
$USAGE
    = "$me [--help] [--debug] \n"
    . " --server=localhost \n"
    . " --port=8000 \n"
    . " [ --c=listResources [ --r ] \| \n"
    . "   --c=createResource --des=descripcio --gra=granularitat \| \n"
    . "   --c=getResource    --id=idResource \| \n"
    . "   --c=delResource    --id=idResource \| \n"
    . "   --c=updateResource --id=idResource --des=descripcio --gra=granularitat \| \n"
    . "   --c=createBooking  --id=idResource --from=31/12/2009_00:00:00 --to=2009/12/31_23:59:00:00 \| \n"
    . "   --c=getBooking     --id=idResource --idB=idBooking \| \n"
    . "   --c=delBooking     --id=idResource --idB=idBooking \| \n"
    . "   --c=updateBooking  --id=idResource --idB=idBooking --from=31/12/2009_00:00:00 --to=2009/12/31_23:59:00:00 ]\n"
    . " ";

$OPT_COMMAND = "" if !( defined($OPT_COMMAND) );

if ($opt_show_help) {
    print $USAGE;
    exit(0);

    # show_help();
}

#######################################################################
#
# kernel of script.
#
my $server = "$OPT_SERVER:$OPT_PORT";
print "Server = " . $server . "\n";
my $client = Client->new($server);
defined $client or die "client NO created\n";

#######################################################################
#
# switch case of the script.
#

my $result = "";
if ( $OPT_COMMAND eq "listResources" ) {
    my @result = $client->listResources();
    foreach my $i (@result) {
        $result .= " " . $i . "\n";
    }
}
elsif ( $OPT_COMMAND eq "createResource" ) {
    $result = $client->createResource( $OPT_PARAM_DES, $OPT_PARAM_GRA );
}
elsif ( $OPT_COMMAND eq "getResource" ) {
    my $r = $client->getResource($OPT_PARAM_ID);
    if ( defined $r ) {
        $result = " resource = " . $OPT_PARAM_ID . " ::\n";
        $result .= " description = " . $r->{description} . "\n";
        $result .= " granularity = " . $r->{granularity} . " .\n";
    }
}
elsif ( $OPT_COMMAND eq "delResource" ) {
    $result = $client->delResource($OPT_PARAM_ID);
}
elsif ( $OPT_COMMAND eq "updateResource" ) {
    print "\n" . $OPT_PARAM_ID . "\n";
    $result = $client->updateResource( $OPT_PARAM_ID, $OPT_PARAM_DES,
        $OPT_PARAM_GRA );
}
elsif ( $OPT_COMMAND eq "createBooking" ) {
    my @OPT_PARAM_FROM = $OPT_PARAM_FROM =~ /(\d+)/g;
    my @OPT_PARAM_TO   = $OPT_PARAM_TO   =~ /(\d+)/g;

    my $FROM = {
        year   => $OPT_PARAM_FROM[0],
        month  => $OPT_PARAM_FROM[1],
        day    => $OPT_PARAM_FROM[2],
        hour   => $OPT_PARAM_FROM[3],
        minute => $OPT_PARAM_FROM[4],
        second => $OPT_PARAM_FROM[5],
    };
    my $TO = {
        year   => $OPT_PARAM_TO[0],
        month  => $OPT_PARAM_TO[1],
        day    => $OPT_PARAM_TO[2],
        hour   => $OPT_PARAM_TO[3],
        minute => $OPT_PARAM_TO[4],
        second => $OPT_PARAM_TO[5],
    };
    print Dumper($OPT_PARAM_ID);
    print Dumper($OPT_PARAM_ID_B);
    print Dumper($FROM);
    print Dumper($TO);

    $result = $client->createBooking( $OPT_PARAM_ID, $FROM, $TO );
}
elsif ( $OPT_COMMAND eq "getBooking" ) {
    $result = $client->getBooking( $OPT_PARAM_ID, $OPT_PARAM_ID_B );
    $result = Dumper($result);
}
elsif ( $OPT_COMMAND eq "delBooking" ) {
    $result = $client->delBooking( $OPT_PARAM_ID, $OPT_PARAM_ID_B );
}
elsif ( $OPT_COMMAND eq "updateBooking" ) {
    my @OPT_PARAM_FROM = $OPT_PARAM_FROM =~ /(\d+)/g;
    my @OPT_PARAM_TO   = $OPT_PARAM_TO   =~ /(\d+)/g;

    my $FROM = {
        year   => $OPT_PARAM_FROM[0],
        month  => $OPT_PARAM_FROM[1],
        day    => $OPT_PARAM_FROM[2],
        hour   => $OPT_PARAM_FROM[3],
        minute => $OPT_PARAM_FROM[4],
        second => $OPT_PARAM_FROM[5],
    };
    my $TO = {
        year   => $OPT_PARAM_TO[0],
        month  => $OPT_PARAM_TO[1],
        day    => $OPT_PARAM_TO[2],
        hour   => $OPT_PARAM_TO[3],
        minute => $OPT_PARAM_TO[4],
        second => $OPT_PARAM_TO[5],
    };
    print Dumper($OPT_PARAM_ID);
    print Dumper($OPT_PARAM_ID_B);
    print Dumper($FROM);
    print Dumper($TO);

    $result = $client->updateBooking( $OPT_PARAM_ID, $OPT_PARAM_ID_B, $FROM,
        $TO );
}
else {
    print "No command, No action ...\n --help for help\n";
    exit(0);
}

if ( !$result ) {

    my $causa = "Showing errors and quit";
    die $causa;
}
else {
    print "" .

        #	"---Smeagol---\n".
        $result . "___Smeagol___\n";
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
    --port <number>   Listen on port <number> (default: 80)
    --comand <exemples>
    --help            Show this message

END
}
