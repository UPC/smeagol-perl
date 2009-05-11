package Smeagol::Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use CGI qw();
use XML::LibXML;
use Carp;
use Data::Dumper;
use Smeagol::DataStore;
use Smeagol::Tag;
use Smeagol::Booking;
use Smeagol::Agenda;
use Smeagol::Resource;
use Smeagol::Resource::List;
use Encode;
use HTTP::Status qw(status_message);

use constant { 
    STATUS_OK                 => 200,
    STATUS_CREATED            => 201,
    STATUS_BAD_REQUEST        => 400,
    STATUS_FORBIDDEN          => 403,
    STATUS_NOT_FOUND          => 404,
    STATUS_METHOD_NOT_ALLOWED => 405,
    STATUS_CONFLICT           => 409,
};

# Constructor needs two arguments: port to listen to, and datastore full path.
# For example:
#    Smeagol::Server->new( 8000, datastorepath => '/tmp/smeagol_datastore' );
sub new {
    my $class = shift;
    my ( $port, %args ) = @_;

    Smeagol::DataStore::init( $args{'datastorepath'} );

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
    '/resources'      => { GET => \&_list_resources, },
    '/resource/(\d+)' => {
        GET    => \&_retrieve_resource,
        DELETE => \&_delete_resource,
        POST   => \&_update_resource,
    },
    '/resource'                     => { POST => \&_create_resource, },
    '/resource/(\d+)/bookings'      => { GET  => \&_list_bookings, },
    '/resource/(\d+)/bookings/ical' => { GET  => \&_list_bookings_ical, },
    '/resource/(\d+)/booking'       => { POST => \&_create_booking, },
    '/resource/(\d+)/tag'           => { POST => \&_create_tag, },
    '/resource/(\d+)/tags'          => { GET  => \&_list_tags, },
    '/resource/(\d+)/tag/([\w.:_\-]+)' => { DELETE => \&_delete_tag, },
    '/resource/(\d+)/booking/(\d+)'    => {
        GET    => \&_retrieve_booking,
        POST   => \&_update_booking,
        DELETE => \&_delete_booking,
    },
    '/resource/(\d+)/booking/(\d+)/ical' =>
        { GET => \&_retrieve_booking_ical },
    '/css/(\w+)\.css' => { GET => \&_send_css },
    '/dtd/(\w+)\.dtd' => { GET => \&_send_dtd },
    '/xsl/(\w+)\.xsl' => { GET => \&_send_xsl },
    '/'               => {
        GET => sub { _send_html( $_[0], "server" ) }
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
            _send_error(STATUS_METHOD_NOT_ALLOWED);
        }
    }
    else {

        # Requested URL not available
        _send_error(STATUS_NOT_FOUND);
    }
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
}

# Prints an Http response. Message is optional.
sub _send_error {
    my ( $status, $text ) = @_;

    #
    # FIXME: Since we're returning XML most of the time,
    #        shouldn't we returning errors as XML too?
    #        (ticket:114)
    #
    _reply( $status, 'text/plain', $text );
}

sub _send_xml {
    my ( $xml, %args ) = @_;

    # default status for XML is OK
    $args{status} ||= STATUS_OK;

    _reply( $args{status}, 'text/xml', $xml );
}

sub _send_ical {
    my ($ical) = @_;

    _reply(
        STATUS_OK,
        'text/calendar; charset=UTF-8',
        encode( 'UTF-8', $ical )
    );
}

##############################################################
# Handlers for resources
##############################################################

sub _list_resources {
    my $list = Smeagol::Resource::List->new();
    _send_xml( $list->to_xml( "/resources", 1 ) );
}

sub _create_resource {
    my ($cgi) = @_;

    my $r = Smeagol::Resource->from_xml( $cgi->param('POSTDATA') );

    if ( !defined $r ) {    # wrong XML argument
        _send_error(STATUS_BAD_REQUEST);
    }
    else {
        $r->save();
        _send_xml( $r->to_xml( "", 1 ), status => 201 );
    }
}

sub _retrieve_resource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($id);

    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
    }
    else {
        _send_xml( $r->to_xml( "", 1 ) );
    }
}

sub _delete_resource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($id);

    if ( !defined $r ) {
        _send_error( STATUS_NOT_FOUND, "Resource #$id does not exist" );
    }
    else {
        $r->remove();
        _send_error( STATUS_OK, "Resource #$id deleted" );
    }
}

sub _update_resource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $updated_resource
        = Smeagol::Resource->from_xml( $cgi->param('POSTDATA'), $id );

    if ( !defined $updated_resource ) {
        _send_error(STATUS_BAD_REQUEST);
    }
    elsif ( !defined Smeagol::Resource->load($id) ) {
        _send_error(STATUS_NOT_FOUND);
    }
    else {
        $updated_resource->save();
        _send_xml( $updated_resource->to_xml( "", 1 ) );
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
    #        (ticket:34)
    #
    if ( open my $dtd, "<", "share/dtd/$id.dtd" ) {

        # slurp dtd file
        local $/;
        _reply( STATUS_OK, 'text/sgml', <$dtd> );
    }
    else {
        _send_error(STATUS_BAD_REQUEST);
    }
}

#
# FIXME: this call is made as _list_bookings($cgi, $1, $2, ...);
#        $2 is always undef since this regex captures 1 item only,
#        thus the undef on the args list below.
#        (ticket:115)
#
sub _list_bookings {
    my ( $cgi, $idResource, undef, $viewAs ) = @_;

    my $r = Smeagol::Resource->load($idResource);

    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ical = $r->agenda->ical;
        _send_ical("$ical");
    }
    else {
        my $xml = $r->agenda->to_xml( $r->url, 1 );
        _send_xml($xml);
    }
}

sub _list_bookings_ical {
    _list_bookings( @_, "ical" );
}

sub _create_booking {
    my ( $cgi, $idResource ) = @_;

    if ( !defined $idResource ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $b = Smeagol::Booking->from_xml( $cgi->param('POSTDATA') );
    if ( !defined $b ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $ag = $r->agenda;

    if ( $ag->interlace($b) ) {
        my $overlapping_agenda = Smeagol::Agenda->new();
        my @overlapping = grep { $_->intersects($b) } $ag->elements;
        foreach my $aux (@overlapping) {
            $overlapping_agenda->append($aux);
        }

        _send_xml( $overlapping_agenda->to_xml( $r->url, 1 ), status => STATUS_CONFLICT );
        return;
    }

    $r->agenda->append($b);
    $r->save();
    _send_xml( $b->to_xml( $r->url, 1 ), status => STATUS_CREATED );
}

sub _retrieve_booking {
    my ( $cgi, $idR, $idB, $viewAs ) = @_;

    if ( !defined $idR || !defined $idB ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ics = $b->ical->calendar->as_string;
        _send_ical($ics);
    }
    else {
        _send_xml( $b->to_xml( $r->url, 1 ) );
    }
}

sub _retrieve_booking_ical {
    _retrieve_booking( @_, "ical" );
}

sub _delete_booking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    $ag->remove($b);
    $r->save();
    _send_error( STATUS_OK, "Booking #$idB deleted" );
}

# NOTE: No race conditions in _update_booking, because
#       we're using HTTP::Server::Simple which has no
#       concurrence management (requests are served
#       sequentially)
sub _update_booking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $old_booking = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $old_booking ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $new_booking
        = Smeagol::Booking->from_xml( $cgi->param('POSTDATA'), $idB );

    if ( !defined $new_booking ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    #
    # Check wether updated booking would produce overlappings
    #
    $ag->remove($old_booking);

    if ( $ag->interlace($new_booking) ) {

        # if overlappings are produced, let's build a new agenda
        # containing affected bookings and return it to the client
        my @overlapping = grep { $_->intersects($new_booking) } $ag->elements;
        my $overlapping_agenda = Smeagol::Agenda->new();

        foreach my $aux (@overlapping) {
            $overlapping_agenda->append($aux);
        }
        $r->agenda($overlapping_agenda);

        _send_xml( $overlapping_agenda->to_xml( $r->url, 1 ), status => STATUS_CONFLICT );
        return;
    }

    $ag->append($new_booking);
    $r->agenda($ag);
    $r->save();

    _send_xml( $new_booking->to_xml( $r->url, 1 ) );
    return;
}

sub _create_tag {
    my ( $cgi, $idResource ) = @_;
    if ( !defined $idResource ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $tg = Smeagol::Tag->from_xml( $cgi->param('POSTDATA') );
    if ( !defined $tg ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    $r->tags->append($tg);
    $r->save();
    _send_xml( $tg->toXML( $r->url, 1 ), status => STATUS_CREATED );
}

sub _list_tags {
    my ( $cgi, $idResource ) = @_;
    my $r = Smeagol::Resource->load($idResource);

    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }
    my $xml = $r->tags->to_xml( $r->url, 1 );
    _send_xml($xml);
}

sub _delete_tag {
    my ( $cgi, $idR, $idT ) = @_;

    if ( !defined $idR || !defined $idT ) {
        _send_error(STATUS_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $tgS = $r->tags;
    if ( !defined $tgS ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    my $tg = ( grep { $_->value eq $idT } $tgS->elements )[0];
    if ( !defined $tg ) {
        _send_error(STATUS_NOT_FOUND);
        return;
    }

    $tgS->remove($tg);
    $r->save();
    _send_error( STATUS_OK, "Tag #$idT deleted" );
}
####################
# Handlers for CSS #
####################

# id should contain the CSS file name (without the ".css" extension)
sub _send_css {
    my ( $cgi, $id ) = @_;

    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find dtd dir
    #        (ticket:116)
    if ( open my $css, "<", "share/css/$id.css" ) {

        # slurp css file
        local $/;
        _reply( STATUS_OK, 'text/css', <$css> );
    }
    else {
        _send_error(STATUS_BAD_REQUEST);
    }
}

####################
# Handlers for XSL #
####################

# id should contain the XSL file name (without the ".xsl" extension)
sub _send_xsl {
    my ( $cgi, $id ) = @_;

    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find dtd dir
    #        (ticket:116)
    if ( open my $xsl, "<", "share/xsl/$id.xsl" ) {

        # slurp css file
        local $/;
        _reply( STATUS_OK, 'application/xml', <$xsl> );
    }
    else {
        _send_error(STATUS_BAD_REQUEST);
    }
}

#####################
# Handler for index #
#####################

sub _send_html {
    my ( $cgi, $filename ) = @_;

    # FIXME: make it work from anywhere, now it must run from
    #        the project base dir or won't find dtd dir
    #        (ticket:116)
    if ( open my $html, "<", "share/html/$filename.html" ) {

        # slurp html file
        local $/;
        _reply( STATUS_OK, 'text/html; charset=UTF-8', <$html> );
    }
    else {
        _send_error(STATUS_BAD_REQUEST);
    }
}

1;
