package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use CGI qw();
use Carp;

use Resource;

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
        POST  => \&_update_resource,
    },
    '/resource' => {
        POST => \&_create_resource,
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
            #carp "\n*** Serving request for $url_key method $method, id #$id ***";
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


# Returns XML representation of a given ID, including 
# all REST decoration stuff (xlink resource locator)
sub _rest_resource_to_xml {
    my ($resource) = shift;
    my ($include_ns)
        = shift; # wether to include or not the Xlink namespace declaration in
                 # result string (it might already been declared in
                 # an external tag where this xml fragment is included)

    my $xml          = $resource->to_xml();
    my $resource_url = _rest_get_resource_url($resource);

    # Add xlink decorations to <resource>, <agenda> and <booking> tag elements
    # We could use XML::LibXML DOM interface, but Perl regex are easier
    # (I never tought I would say something like this)
    if ($include_ns) {
        $xml
            =~ s|<\s*resource\s*>|<resource xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="$resource_url">|g;
    }
    else {
        $xml
            =~ s|<\s*resource\s*>|<resource xlink:type="simple" xlink:href="$resource_url">|g;
    }

    $xml
        =~ s|<\s*agenda\s*>|<agenda xlink:type="simple" xlink:href="$resource_url/bookings">|g;

    # FIXME: Bookings must have IDs???
    $xml
        =~ s|<\s*booking\s*>|<booking xlink:type="simple" xlink:href="$resource_url/bookings/ID">|g;

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
    my $xml
        = '<resources xmlns:xlink="http://www.w3.org/1999/xlink" xlink:type="simple" xlink:href="/resources">';
    foreach my $id ( Resource->list_id ) {
        my $r = Resource->load($id);
        if ( defined $r ) {
            $xml .= _rest_resource_to_xml($r, 0);
        }
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
    # FIXME: this will never happen: clients don't provide resource IDs!!!
    #elsif ( defined Resource->load( $id ) ) {
    #    _status( 403, "Resource #$id already exists!" );
    #}
    else {
        $r->save();
        _status( 201, _rest_resource_to_xml($r, 1) );
    }
}


sub _retrieve_resource {
    my $cgi = shift;
    my $id = shift;

    if ( !defined $id ) {
        _status(400);
        return;
    }

    my $r = Resource->load($id);

    if ( !defined $r ) {
        _status(404);
    }
    else {
        _send_xml( _rest_resource_to_xml($r, 1) );
    }
}


sub _delete_resource {
    my $cgi = shift;
    my $id = shift;

    if (!defined $id) {
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
    my $id = shift;

    if (!defined $id) {
        _status(400);
        return;
    }

    my $updated_resource = Resource->from_xml( $cgi->param('POSTDATA') );

    if ( !defined $updated_resource ) {
        _status(400);
    }
    elsif ( !defined Resource->load( $id ) ) {
        _status(404);
    }
    else {
        $updated_resource->id($id); # change id so updated resource will overwrite old resource
        $updated_resource->save();
        _send_xml( _rest_resource_to_xml($updated_resource) );
    }
}

1;
