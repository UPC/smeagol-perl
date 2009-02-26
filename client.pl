#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use YAML qw(LoadFile);
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
my $OPT_PORT = '8000';
my $OPT_COMMAND;
my $OPT_PARAM_ID;
my $OPT_PARAM_DES;
my $OPT_PARAM_GRA;
my $OPT_PARAM_FROM;
my $OPT_PARAM_TO;
my $OPT_PARAM_R;

my @OPT_PARAM_FROM;
my @OPT_PARAM_TO;

    # parse command-line options

    my $opt_show_help = '';

    my $options = GetOptions(
        "server=s"  => \$OPT_SERVER,        # server
        "port=i"    => \$OPT_PORT,          # port
        "c=s"       => \$OPT_COMMAND,       # command
        "id=i"      => \$OPT_PARAM_ID,      #
        "des=s"     => \$OPT_PARAM_DES,     #
        "gra=s"     => \$OPT_PARAM_GRA,     #
        "from=s"    => \$OPT_PARAM_FROM,    #
        "to=s"      => \$OPT_PARAM_TO,      #
        "r"         => \$OPT_PARAM_R,       # recursive
        "help"      => \$opt_show_help
	# =i means "requires numeric value"
	# =s means "requires string value"
    );

    my ($me) = $0 =~ m{.*/(.*)};
    $me = $0 if !(defined($me));
    $USAGE
        =  "$me [--help] [--debug] \n"
        .  " --server=localhost \n"
        .  " --port=8000 \n"
	.  " [ --c=listResources [ --r ] \| \n"
	.  "   --c=createResource --des=descripcio --gra=granularitat \| \n"
	.  "   --c=getResource    --id=idResource \| \n"
	.  "   --c=delResource    --id=idResource \| \n"
	.  "   --c=updateResource --id=idResource --des=descripcio --gra=granularitat \| \n"
	.  "   --c=createAgenda   --id=idResource \| \n"
	.  "   --c=getAgenda      --id=idAgenda \| \n"
	.  "   --c=delAgenda      --id=idAgenda \| \n"
	.  "   --c=updateAgenda   --id=idAgenda \| \n"
	.  "   --c=createBooking  --id=idAgenda --from=31/12/2009_00:00 --to=2009/12/31_23:59:00 \| \n"
	.  "   --c=getBooking     --id=idBooking \| \n"
	.  "   --c=delBooking     --id=idBooking \| \n"
	.  "   --c=updateBooking  --id=idBooking --from=31/12/2009_00:00 --to=2009/12/31_23:59:00 ]\n"
	.  " ";

    $OPT_COMMAND = "" if !(defined($OPT_COMMAND));

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
# print $server."\n";
my $client = Client->new($server);
# if ( ref $client eq 'Client' ) { print "client created\n" } else { print "NOOOO\n" };

#######################################################################
#
# switch case of the script.
#

my $result = "";
if ( $OPT_COMMAND eq "listResources" ) {
    my @result = $client->listResources( );
	foreach my $i (@result) {
		$result.= " ".$i."\n";
	}
}
elsif ( $OPT_COMMAND eq "createResource" ) {
    $result = $client->createResource( $OPT_PARAM_DES , $OPT_PARAM_GRA );
}
elsif ( $OPT_COMMAND eq "getResource" ) {
    my $r = $client->getResource( "\/resource\/".$OPT_PARAM_ID );
    if (defined $r) {
	$result = " resource/".$OPT_PARAM_ID." ::\n";
	$result.= " description = ".$r->{description}."\n";
	$result.= " granularity = ".$r->{granularity}."\n";
    }
}
elsif ( $OPT_COMMAND eq "delResource" ) {
    $result = $client->delResource( "\/resource\/".$OPT_PARAM_ID );
}
elsif ( $OPT_COMMAND eq "updateResource" ) {
print $OPT_PARAM_ID."\n";
    $result = $client->updateResource( "\/resource\/".$OPT_PARAM_ID , $OPT_PARAM_DES , $OPT_PARAM_GRA );
}
elsif ( $OPT_COMMAND eq "createAgenda" ) {
    $result = $client->createAgenda( $OPT_PARAM_ID ); # idResource
}
elsif ( $OPT_COMMAND eq "getAgenda" ) {
    $result = $client->getAgenda( $OPT_PARAM_ID ); # idAgenda
}
elsif ( $OPT_COMMAND eq "delAgenda" ) {
    $result = $client->delAgenda( $OPT_PARAM_ID ); # idAgenda
}
elsif ( $OPT_COMMAND eq "updateAgenda" ) {
    $result = $client->updateAgenda( $OPT_PARAM_ID ); # idAgenda # te sentit aquesta operació?
}
elsif ( $OPT_COMMAND eq "createBooking" ) {
    @OPT_PARAM_FROM = $OPT_PARAM_FROM =~ /(\d+)/g ;
    @OPT_PARAM_TO = $OPT_PARAM_TO =~ /(\d+)/g;
print Dumper(@OPT_PARAM_FROM);
print Dumper(@OPT_PARAM_TO);
    $result = $client->createBooking( $OPT_PARAM_ID, @OPT_PARAM_FROM, @OPT_PARAM_TO );
}
elsif ( $OPT_COMMAND eq "getBooking" ) {
    $result = $client->getBooking( $OPT_PARAM_ID );
}
elsif ( $OPT_COMMAND eq "delBooking" ) {
    $result = $client->delBooking( $OPT_PARAM_ID );
}
elsif ( $OPT_COMMAND eq "updateBooking" ) {
    @OPT_PARAM_FROM = $OPT_PARAM_FROM =~ /(\d+)/g;
    @OPT_PARAM_TO = $OPT_PARAM_TO =~ /(\d+)/g;
    $result = $client->updateBooking( $OPT_PARAM_ID, @OPT_PARAM_FROM, @OPT_PARAM_TO );
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
    print "".
#	"---Smeagol---\n".
	$result.
	"___Smeagol___\n";
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
