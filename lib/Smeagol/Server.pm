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

our @EXPORT_OK = qw(sendXML sendError sendICal);

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
my %crudFor = (
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
        GET => sub { _sendFile( 'text/css', @_ ) }
    },
    '/(dtd/\w+\.dtd)' => {
        GET => sub { _sendFile( 'text/sgml', @_ ) }
    },
    '/(xsl/\w+\.xsl)' => {
        GET => sub { _sendFile( 'application/xml', @_ ) }
    },
    '/' => {
        GET => sub {
            _sendFile( 'text/html; charset=UTF-8', $_[0],
                "html/server.html" );
            }
    },
);

# Http request dispatcher. Sends every request to the corresponding
# handler according to hash %crud_for. The handler receives
# the CGI object and the list of parameters acording to the corresponding
# groups in the %crud_for regular expressions.
sub handle_request {
    my $self = shift;
    my $cgi  = shift;

    my $pathInfo = $cgi->path_info();
    my $method   = $cgi->request_method();

    # Find the corresponding action
    my $urlKey = 'default_action';
    my @ids;

    foreach my $urlPattern ( keys(%crudFor) ) {

        # Anchor pattern and allow URLs ending in '/'
        my $pattern = '^' . $urlPattern . '/?$';
        if ( $pathInfo =~ m{$pattern} ) {
            @ids = ( $1, $2 );
            $urlKey = $urlPattern;
            last;
        }
    }

    # Dispatch to the corresponding action.
    # Pass parameters obtained from the pattern to action
    if ( exists $crudFor{$urlKey} ) {
        if ( exists $crudFor{$urlKey}->{$method} ) {
            $crudFor{$urlKey}->{$method}->( $cgi, $ids[0], $ids[1] );
        }
        else {

            # Requested HTTP method not available
            sendError(HTTP_METHOD_NOT_ALLOWED);
        }
    }
    else {

        # Requested URL not available
        sendError(HTTP_NOT_FOUND);
    }

    _logRequest( $method, $cgi ) if $VERBOSE_MODE;
}

# _logRequest(method, cgi):
#       generate log messages conforming to Apache Combined Log format,
#       as defined in http://httpd.apache.org/docs/2.2/logs.html#accesslog
#       FIXME: Several fields have a hard-coded "-" value (i.e. user ident,
#              user ID and response object size).
sub _logRequest {
    my ( $method, $cgi ) = @_;
    my $strDate = POSIX::strftime( "%d/%b/%Y:%H:%M:%S %z", localtime() );
    my $rhost   = $cgi->remote_host();
    my $uri     = $cgi->request_uri();
    my $proto
        = defined( $cgi->server_protocol() )
        ? uc( $cgi->server_protocol() )
        : "-";
    my $referer
        = defined( $cgi->referer() ) ? q["] . $cgi->referer() . q["] : '-';
    my $ua
        = defined( $cgi->user_agent() )
        ? q["] . $cgi->user_agent() . q["]
        : '-';

    print STDERR
        "$rhost - - [$strDate] \"$method $uri $proto\" - - $referer $ua\n";
}

#############################################################
# Http tools
#############################################################

#
# reply: Generate generic HTTP response.
#
# Expected arguments are:
#    status (required) => HTTP status code (200, 201, 404, etc.)
#    headers => array containing a list of strings representing HTTP headers
#    body => string containing response body
#
# Example:
#   reply( status  => HTTP_OK,
#                  headers => ('Content-type: text/plain', ),
#                  body    => 'hello world');
#
sub reply {
    my (%args) = @_;

    croak "missing required 'status' argument" unless defined $args{status};

    my $msg = status_message( $args{status} );
    croak( "unknown status code " . $args{status} ) unless defined $msg;

    print "HTTP/1.0 ", $args{status}, " $msg\n";
    foreach ( $args{headers} ) {
        print $_, "\n";
    }
    print "\n";

    print $args{body}, "\n" if defined $args{body};

    return $args{status};
}

# Prints an Http response. Message is optional.
sub sendError {
    my ( $status, $text ) = @_;

    #
    # FIXME: Since we're returning XML most of the time,
    #        shouldn't we returning errors as XML too?
    #        (ticket:114)
    #

    reply(
        status  => $status,
        headers => ( 'Content-type: text/plain', ),
        body    => $text
    );
}

sub sendXML {
    my ( $xml, %args ) = @_;

    # default status for XML is OK
    $args{status} ||= HTTP_OK;

    reply(
        status  => $args{status},
        headers => ( 'Content-type: text/xml', ),
        body    => $xml
    );
}

sub sendICal {
    my ($ical) = @_;

    reply(
        status  => HTTP_OK,
        headers => ( 'text/calendar; charset=UTF-8', ),
        body    => encode( 'UTF-8', $ical )
    );
}

#####################
# Handler for index #
#####################

sub _sendFile {
    my ( $mime, $cgi, $filename ) = @_;

    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find file dir
    #        (ticket:116)
    if ( open my $file, "<", "share/$filename" ) {

        # slurp html file
        local $/;

        reply(
            status  => HTTP_OK,
            headers => ( "Content-type: $mime", ),
            body    => <$file>
        );
    }
    else {
        sendError(HTTP_BAD_REQUEST);
    }
}

1;
