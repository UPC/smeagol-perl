package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use CGI qw(header);

use Resource;

my %resource_db;

my $r = Resource->new(
    '10',
    'aula chachipilongui',
    'granularitat chachipilongui'
);
$resource_db{ $r->{id} } = $r;

# Nota: hauria de funcionar amb "named groups" però només
# s'implementen a partir de perl 5.10. Quina misèria, no?
# A Python fa temps que funcionen...
#
# Dispatcher table. Associates a handler to an URL. Groups in
# the URL pattern are given as parameters to handler.
my %crud_for = (
    '/resources'      => { GET => \&_list_resources, },
    '/resource/(\d+)' => {
        GET    => \&_retrieve_resource,
        DELETE => \&_delete_resource,
    },
    '/resource'                => { POST => \&_create_resource, },
    '/resource/(\d+)/bookings' => {},
    '/booking/(\d+)'           => {},
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
    foreach my $url_pattern ( keys(%crud_for) ) {

        # Anchor pattern and allow URLs ending in '/'
        my $pattern = '^' . $url_pattern . '/?$';
        if ( $path_info =~ m{$pattern} ) {
            $url_key = $url_pattern;
            last;
        }
    }

    # Dispatch to the corresponding action.
    # Pass parameters obtained from the pattern to action
    if ( exists $crud_for{$url_key} ) {
        if ( exists $crud_for{$url_key}->{$method} ) {
            $crud_for{$url_key}->{$method}->( $cgi, $1 );
        }
        else {

            # Requested HTTP method not available
            _status(405);
        }
    }
    else {

        # Requested URL not available
        _status(404);
    }
}

#############################################################
# Http tools
#############################################################

sub _reply {
    my ( $status, $type, @output ) = @_;

    $type = 'text/plain' unless defined $type and $type ne '';
    print "HTTP/1.0 $status\n", header($type), @output, "\n";
}

# Prints an Http response. Message is optional.
sub _status {
    my ( $code, $message ) = @_;

    my %codes = (
        200 => 'OK',
        201 => 'Created',
        400 => 'Bad Request',
        403 => 'Forbidden',
        404 => 'Not Found',
        405 => 'Method Not Allowed',
    );

    my $text = $codes{$code} || die "Unknown HTTP code error";
    _reply( "$code $codes{$code}", 'text/plain', $message || $text );
}

sub _send_xml {
    my $xml = shift;

    _reply( '200 OK', 'text/xml', $xml );
}

##############################################################
# Handlers for resources
##############################################################

sub _list_resources {
    my $xml = "<resources>";
    foreach my $id ( keys(%resource_db) ) {
        $xml .= $resource_db{$id}->to_xml();
    }
    $xml .= "</resources>";
    _send_xml($xml);
}

sub _create_resource {
    my $cgi = shift;

    my $r = Resource->from_xml( $cgi->param('POSTDATA') );

    if ( !defined $r ) {    # wrong XML argument
        _status(400);
    }
    elsif ( exists $resource_db{ $r->{id} } ) {
        _status( 403, "Resource $r->{id} already exists!" );
    }
    else {
        $resource_db{ $r->{id} } = $r;
        _status( 201, "Resource #$r->{id} created" );
    }
}

sub _retrieve_resource {
    my $cgi = shift;
    my $id  = shift;

    if ( !defined $id ) {
        _status(400);
    }
    elsif ( !exists $resource_db{$id} ) {
        _status(404);
    }
    else {
        _send_xml( $resource_db{$id}->to_xml() );
    }
}

sub _delete_resource {
    my ( undef, $id ) = @_;

    _reply( '200 OK', 'text/plain', "Resource #$id deleted" );
}

1;
