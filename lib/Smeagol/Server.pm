package Smeagol::Server;

use strict;
use warnings;

use base qw(Exporter HTTP::Server::Simple::CGI);
use CGI qw();
use Carp;
use Smeagol::DataStore;
use Encode;
use HTTP::Status qw(:constants status_message);
use Smeagol::Server::Handler
    qw(listResources retrieveResource deleteResource updateResource createResource listBookings listBookingsIcal createBooking createTag listTags deleteTag retrieveBooking updateBooking deleteBooking retrieveBookingIcal);
use POSIX ();

our @EXPORT_OK = qw(send_xml send_error send_ical);

my $REQUEST_TIMEOUT = 60;
my $VERBOSE_MODE;    # server logs disabled by default

# Don't die on SIGALRM, don't do anything, just stop sysreading
$SIG{ALRM} = sub { };

sub accept_hook {

    # First, let the parent do its magic
    shift->SUPER::accept_hook(@_);

    # Then, start timer for lazy requests
    alarm($REQUEST_TIMEOUT);
}

sub post_setup_hook {

    # Stop timer for lazy requests
    alarm(0);

    # Then do as parent says
    shift->SUPER::post_setup_hook(@_);
}

# Constructor needs two arguments: port to listen to, and datastore full path.
# For example:
#    Smeagol::Server->new( 8000, datastorepath => '/tmp/smeagol_datastore' );
sub new {
    my $class = shift;
    my ( $port, %args ) = @_;

    Smeagol::DataStore::init( $args{'datastorepath'} );
    $REQUEST_TIMEOUT = $args{'timeout'} if defined $args{'timeout'};
    $VERBOSE_MODE = $args{'verbose'};

    my $obj = $class->SUPER::new($port);

    bless $obj, $class;
    return $obj;
}

sub print_banner {

    # dummy banner which prints nothing, because parent class's is buggy
    # (always shows a "listening on http://localhost..." message)
}

# Nota: hauria de funcionar amb "named groups" però només
# s'implementen a partir de perl 5.10. Quina misèria, no?
# A Python fa temps que funcionen...
#
# Dispatcher table. Associates a handler to an URL. Groups in
# the URL pattern are given as parameters to handler.
my %crud_for = (
    '/resources'      => { GET => \&listResources, },
    '/resource/(\d+)' => {
        GET    => \&retrieveResource,
        DELETE => \&deleteResource,
        POST   => \&updateResource,
    },
    '/resource'                        => { POST   => \&createResource, },
    '/resource/(\d+)/bookings'         => { GET    => \&listBookings, },
    '/resource/(\d+)/bookings/ical'    => { GET    => \&listBookingsIcal, },
    '/resource/(\d+)/booking'          => { POST   => \&createBooking, },
    '/resource/(\d+)/tag'              => { POST   => \&createTag, },
    '/resource/(\d+)/tags'             => { GET    => \&listTags, },
    '/resource/(\d+)/tag/([\w.:_\-]+)' => { DELETE => \&deleteTag, },
    '/resource/(\d+)/booking/(\d+)'    => {
        GET    => \&retrieveBooking,
        POST   => \&updateBooking,
        DELETE => \&deleteBooking,
    },
    '/resource/(\d+)/booking/(\d+)/ical' => { GET => \&retrieveBookingIcal },
    '/(css/\w+\.css)'                    => {
		GET => sub{_send_file( 'text/css', @_ ) }
	},
    '/(dtd/\w+\.dtd)'                    => {
		GET => sub{_send_file( 'text/sgml', @_ ) }
	},
    '/(xsl/\w+\.xsl)'                    => {
		GET => sub{_send_file( 'application/xml', @_ ) }
	 },
    '/'                                  => {
        GET => sub { _send_file( 'text/html; charset=UTF-8', $_[0], "html/server.html" ) }
    },
);

# Http request dispatcher. Sends every request to the corresponding
# handler according to hash %crud_for. The handler receives
# the CGI object and the list of parameters acording to the corresponding
# groups in the %crud_for regular expressions.
sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $path_info = $cgi->path_info();
    my $method    = $cgi->request_method();

    # Find the corresponding action
    my $url_key = 'default_action';
    my @ids;

    foreach my $url_pattern ( keys(%crud_for) ) {

        # Anchor pattern and allow URLs ending in '/'
        my $pattern = '^' . $url_pattern . '/?$';
        if ( $path_info =~ m{$pattern} ) {
            @ids = ( $1, $2 );
            $url_key = $url_pattern;
            last;
        }
    }

    # Dispatch to the corresponding action.
    # Pass parameters obtained from the pattern to action
    if ( exists $crud_for{$url_key} ) {
        if ( exists $crud_for{$url_key}->{$method} ) {
            $crud_for{$url_key}->{$method}->( $cgi, $ids[0], $ids[1] );
        }
        else {

            # Requested HTTP method not available
            send_error(HTTP_METHOD_NOT_ALLOWED);
        }
    }
    else {

        # Requested URL not available
        send_error(HTTP_NOT_FOUND);
    }

    _log_request( $method, $cgi ) if $VERBOSE_MODE;
}

# _log_request(method, cgi):
#       generate log messages conforming to Apache Combined Log format,
#       as defined in http://httpd.apache.org/docs/2.2/logs.html#accesslog
#       FIXME: Several fields have a hard-coded "-" value (i.e. user ident,
#              user ID and response object size).
sub _log_request {
    my ( $method, $cgi ) = @_;
    my $strDate = POSIX::strftime( "%d/%b/%Y:%H:%M:%S - %z", localtime() );
    my $rhost   = $cgi->remote_host();
    my $uri     = $cgi->request_uri();
    my $proto
        = defined( $cgi->server_protocol() )
        ? uc( $cgi->server_protocol() )
        : "-";
    my $referer = defined( $cgi->referer() )    ? $cgi->referer()    : "-";
    my $ua      = defined( $cgi->user_agent() ) ? $cgi->user_agent() : "-";

    print STDERR
        "$rhost - - [$strDate] \"$method $uri $proto\" - \"$referer\" \"$ua\"\n";
}

#############################################################
# Http tools
#############################################################

sub _reply {
    my ( $status, $type, $text ) = @_;

    croak "wrong number of parameters"
        if @_ < 2;

    my $msg = status_message($status);
    croak "unknown status code $status"
        unless defined $msg;

    $text = $msg
        unless defined $text;

    print "HTTP/1.0 $status $msg\n", CGI->header($type), $text, "\n";
    return $status;
}

# Prints an Http response. Message is optional.
sub send_error {
    my ( $status, $text ) = @_;

    #
    # FIXME: Since we're returning XML most of the time,
    #        shouldn't we returning errors as XML too?
    #        (ticket:114)
    #
    _reply( $status, 'text/plain', $text );
}

sub send_xml {
    my ( $xml, %args ) = @_;

    # default status for XML is OK
    $args{status} ||= HTTP_OK;

    _reply( $args{status}, 'text/xml', $xml );
}

sub send_ical {
    my ($ical) = @_;

    _reply(
        HTTP_OK,
        'text/calendar; charset=UTF-8',
        encode( 'UTF-8', $ical )
    );
}

#####################
# Handler for index #
#####################

sub _send_file {
	my ( $mime, $cgi, $filename) = @_;

    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find file dir
    #        (ticket:116)
	if ( open my $file, "<", "share/$filename" ) {

        # slurp html file
        local $/;
        _reply( HTTP_OK, $mime, <$file> );
    }
    else {
        send_error(HTTP_BAD_REQUEST);
    }
}


1;
