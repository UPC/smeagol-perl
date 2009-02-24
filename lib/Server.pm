package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use CGI qw();
use XML::LibXML;
use Carp;

use Resource;

my $XML_HEADER = '<?xml version="1.0" encoding="UTF-8"?>'
    . '<?xml-stylesheet href="/css/smeagol.css" type="text/css"?>';

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
        POST   => \&_update_resource,
    },
    '/resource'                     => { POST => \&_create_resource, },
    '/resource/(\d+)/bookings'      => { GET  => \&_list_bookings, },
    '/resource/(\d+)/booking'       => { POST => \&_create_booking, },
    '/resource/(\d+)/booking/(\d+)' => {
        GET    => \&_retrieve_booking,
        POST   => \&_update_booking,
        DELETE => \&_delete_booking,
    },
    '/css/(\w+)\.css' => { GET => \&_send_css },
    '/dtd/(\w+)\.dtd' => { GET => \&_send_dtd },
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
            _status(405);
        }
    }
    else {

        # Requested URL not available
        _status(404);
    }
}

############################
# REST management routines #
############################

# Returns the REST URL which identifies a given resource
sub _rest_get_resource_url {
    my ($resource) = shift;

    return "/resource/" . $resource->id;
}

# Extracts the Resource ID from a given Resource REST URL
sub _rest_parse_resource_url {
    my ($url) = shift;

    if ( $url =~ /\/resource\/(\w+)/ ) {
        return $1;
    }
    else {
        return undef;
    }
}

# Returns the REST URL which identifies the agenda of a given resource
sub _rest_get_agenda_url {
    my ($resource) = shift;
    return _rest_get_resource_url($resource) . "/bookings";
}

# Returns the REST URL which identifies a booking of a given resource
sub _rest_get_booking_url {
    my $booking_id  = shift;
    my $resource_id = shift;

    return '/resource/' . $resource_id . '/booking/' . $booking_id;
}

# Returns XML representation of a given resource, including
# all REST decoration stuff (xlink resource locator)
sub _rest_resource_to_xml {
    my $resource = shift;
    my $is_root_node = shift;

    $is_root_node = ( defined $is_root_node ) ? $is_root_node : 0;

    my $agenda_url = _rest_get_agenda_url($resource);

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string( $resource->to_xml() );

    # Add xlink decorations to <resource>, <agenda> and <booking> elements
    my @nodes = $doc->getElementsByTagName('resource');
    if ($is_root_node) {
        $nodes[0]->setNamespace( "http://www.w3.org/1999/xlink", "xlink", 0 );
    }
    $nodes[0]->setAttribute( "xlink:type", "simple" );
    $nodes[0]
        ->setAttribute( "xlink:href", _rest_get_resource_url($resource) );

    #
    # FIXME: The following loop should be rewritten using _rest_agenda_to_xml
    #
    for my $agenda_node ( $doc->getElementsByTagName('agenda') ) {
        $agenda_node->setAttribute( "xlink:type", 'simple' );
        $agenda_node->setAttribute( "xlink:href",
            _rest_get_agenda_url($resource) );
    }

    #
    # FIXME: The following loop should be rewritten using _rest_booking_to_xml
    #
    for my $booking_node ( $doc->getElementsByTagName('booking') ) {
        my $booking = Booking->from_xml( _rest_remove_xlink_attrs($booking_node->toString()) );
        $booking_node->setAttribute( "xlink:type", 'simple' );
        $booking_node->setAttribute( "xlink:href",
            _rest_get_booking_url( $booking->id, $resource->id ) );
    }

    my $xml = $doc->toString();

    # toString adds an XML preamble, not needed if
    # this is not a root node, so we remove it
    $xml =~ s/<\?xml version="1.0"\?>//;

    if ($is_root_node) {
        $xml = $XML_HEADER . $xml;
    }
    return $xml;

}


sub _rest_remove_xlink_attrs {
    my $xml = shift;

    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_string($xml) or die "_rest_remove_xlink_attrs() received an invalid XML argument";

    my @tags = ('booking', 'agenda', 'resource');

    for my $tag (@tags) {
        for my $node ($doc->getElementsByTagName($tag)) {
            $node->removeAttribute( "xlink:href" );
            $node->removeAttribute( "xlink:type" );
            $node->removeAttribute( "xmlns:xlink" );
        }
    }

    my $result = $doc->toString(0);

    # removeAttribute() cannot remove namespace declarations (WTF!!!)
    # ... and, if you are asking: *no*, removeAttributeNS() does not work, either!),
    # so let's be expeditive:
    $result =~ s/ xmlns:xlink="[^"]*"//g;

    return $result;
}


sub _rest_agenda_to_xml {
    my $resource     = shift;
    my $is_root_node = shift;

    $is_root_node = ( defined $is_root_node ) ? $is_root_node : 0;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string( $resource->agenda->to_xml() );
    my @nodes  = $doc->getElementsByTagName('agenda');
    if ($is_root_node) {
        $nodes[0]->setNamespace( "http://www.w3.org/1999/xlink", "xlink", 0 );
    }
    $nodes[0]->setAttribute( "xlink:type", 'simple' );
    $nodes[0]->setAttribute( "xlink:href", _rest_get_agenda_url($resource) );

    #
    # FIXME: The following loop should be rewritten using _rest_booking_to_xml
    #
    for my $booking_node ( $doc->getElementsByTagName('booking') ) {
        my $booking = Booking->from_xml( _rest_remove_xlink_attrs($booking_node->toString()) );
        $booking_node->setAttribute( "xlink:type", 'simple' );
        $booking_node->setAttribute( "xlink:href",
            _rest_get_booking_url( $booking->id, $resource->id ) );
    }

    my $xml = $doc->toString();

    # toString adds an XML preamble, not needed if
    # this is not a root node, so we remove it
    $xml =~ s/<\?xml version="1.0"\?>//;

    if ($is_root_node) {
        $xml = $XML_HEADER . $xml;
    }
    return $xml;
}


sub _rest_booking_to_xml {
    my ( $booking, $resource_id, $is_root_node ) = shift;

    $is_root_node = ( defined $is_root_node ) ? $is_root_node : 0;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string( $booking->to_xml() );

    my @nodes = $doc->getElementsByTagName('booking');

    # Add XLink attributes
    if ($is_root_node) {
        $nodes[0]->setNamespace( "http://www.w3.org/1999/xlink", "xlink", 0 );
    }
    $nodes[0]->setAttribute( "xlink:type", 'simple' );
    $nodes[0]->setAttribute( "xlink:href",
        _rest_get_booking_url( $booking->id, $resource_id ) );

    my $xml = $doc->toString();

    # toString adds an XML preamble, not needed if
    # this is not a root node, so we remove it
    $xml =~ s/<\?xml version="1.0"\?>//;

    if ($is_root_node) {
        $xml = $XML_HEADER . $xml;
    }
    return $xml;
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
    my $xml = $XML_HEADER
        . '<resources xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="/resources">';
    foreach my $id ( Resource->list_id ) {
        my $r = Resource->load($id);
        if ( defined $r ) {
            $xml .= _rest_resource_to_xml( $r, 0 );
        }
    }
    $xml .= "</resources>";
    _send_xml($xml);
}

sub _create_resource {
    my $cgi = shift;

    my $r = Resource->from_xml( _rest_remove_xlink_attrs($cgi->param('POSTDATA')) );

    if ( !defined $r ) {    # wrong XML argument
        _status(400);
    }
    else {
        $r->save();
        _status( 201, _rest_resource_to_xml( $r, 1 ) );
    }
}

sub _retrieve_resource {
    my $cgi = shift;
    my $id  = shift;

    if ( !defined $id ) {
        _status(400);
        return;
    }

    my $r = Resource->load($id);

    if ( !defined $r ) {
        _status(404);
    }
    else {
        _send_xml( _rest_resource_to_xml( $r, 1 ) );
    }
}

sub _delete_resource {
    my $cgi = shift;
    my $id  = shift;

    if ( !defined $id ) {
        _status(400);
        return;
    }

    my $r = Resource->load($id);

    if ( !defined $r ) {
        _status( 404, "Resource #$id does not exist" );
    }
    else {
        $r->remove();
        _status( 200, "Resource #$id deleted" );
    }
}

sub _update_resource {
    my $cgi = shift;
    my $id  = shift;

    if ( !defined $id ) {
        _status(400);
        return;
    }

    my $updated_resource = Resource->from_xml( _rest_remove_xlink_attrs($cgi->param('POSTDATA')), $id );

    if ( !defined $updated_resource ) {
        _status(400);
    }
    elsif ( !defined Resource->load($id) ) {
        _status(404);
    }
    else {
        $updated_resource->save();
        _send_xml( _rest_resource_to_xml($updated_resource) );
    }
}

##############################################################
# Handlers for DTD
##############################################################

sub _send_dtd {
    my ( $cgi, $id ) = @_;

    #
    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find dtd dir
    #
    if ( open my $dtd, "<", "dtd/$id.dtd" ) {

        # slurp dtd file
        local $/;
        _reply( '200 OK', 'text/sgml', <$dtd> );
    }
    else {
        _status(400);
    }
}

sub _list_bookings {
    my $cgi = shift;
    my $id  = shift;    # Resource ID

    my $r = Resource->load($id);

    if ( !defined $r ) {
        _status(404);
    }
    else {
        my $xml = _rest_agenda_to_xml( $r, 1 );
        _send_xml( $xml );
    }
}

sub _create_booking {

    # FIXME: I'm just a stub
}

sub _retrieve_booking {

    # FIXME: I'm just a stub
}

sub _delete_booking {

    # FIXME: I'm just a stub
}

sub _update_booking {

    # FIXME: I'm just a stub
}

####################
# Handlers for CSS #
####################

sub _send_css {
    my ( $cgi, $id )
        = @_
        ;  #id should contain the CSS file name (without the ".css" extension)

    #
    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find dtd dir

    if ( open my $css, "<", "css/$id.css" ) {

        # slurp css file
        local $/;
        _reply( '200 OK', 'text/css', <$css> );
    }
    else {
        _status(400);
    }
}

1;
