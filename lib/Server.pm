package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use CGI qw();

use Resource;
use DataStore;

DataStore->init_path('/tmp/smeagol_datastore');

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
    '/resource' => {
        POST => \&_create_resource,
        PUT  => \&_update_resource,
    },
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
    my $id;
    foreach my $url_pattern ( keys(%crud_for) ) {

        # Anchor pattern and allow URLs ending in '/'
        my $pattern = '^' . $url_pattern . '/?$';
        if ( $path_info =~ m{$pattern} ) {
            $id      = $1;
            $url_key = $url_pattern;
            last;
        }
    }

    # Dispatch to the corresponding action.
    # Pass parameters obtained from the pattern to action
    if ( exists $crud_for{$url_key} ) {
        if ( exists $crud_for{$url_key}->{$method} ) {
            $crud_for{$url_key}->{$method}->( $cgi, $id );
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
    print "HTTP/1.0 $status\n", CGI->header($type), @output, "\n";
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
    foreach my $id ( DataStore->list_id ) {
        warn $id;
        $xml .= DataStore->load($id);
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
    elsif ( DataStore->exists( $r->{id} ) ) {
        _status( 403, "Resource #$r->{id} already exists!" );
    }
    else {
        DataStore->save( $cgi->param('POSTDATA') );
        _status( 201, $r->to_xml() );
    }
}

sub _retrieve_resource {
    my $cgi = shift;
    my $id  = shift;

    if ( !defined $id ) {
        _status(400);
    }
    elsif ( !DataStore->exists($id) ) {
        _status(404);
    }
    else {
        _send_xml( DataStore->load($id) );
    }
}

sub _delete_resource {
    my ( undef, $id ) = @_;

    if ( !DataStore->exists($id) ) {
        _status( 404, "Resource #$id does not exist" );
    }
    else {
        DataStore->remove($id);
        _status( 200, "Resource #$id deleted" );
    }
}

sub _update_resource {
    my $cgi = shift;

    my $r = Resource->from_xml( $cgi->param('POSTDATA') );

    if ( !defined $r ) {
        _status(400);
    }
    elsif ( !DataStore->exists( $r->{id} ) ) {
        _status(404);
    }
    else {
        my $resource_xml = $r->to_xml();
        DataStore->save($resource_xml);
        _send_xml($resource_xml);
    }
}

1;
