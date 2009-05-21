package Smeagol::Server;

use strict;
use warnings;

use base qw(Exporter HTTP::Server::Simple::CGI);
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
use HTTP::Status qw(:constants status_message);
use Smeagol::Server::Handler qw(listResources retrieveResource deleteResource updateResource createResource listBookings);

our @EXPORT_OK = qw(send_xml send_error send_ical);

my $REQUEST_TIMEOUT = 60;

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
    '/resource'                     => { POST => \&createResource, },
    '/resource/(\d+)/bookings'      => { GET  => \&listBookings, },
    '/resource/(\d+)/bookings/ical' => { GET  => \&_listBookingsIcal, },
    '/resource/(\d+)/booking'       => { POST => \&_createBooking, },
    '/resource/(\d+)/tag'           => { POST => \&_createTag, },
    '/resource/(\d+)/tags'          => { GET  => \&_listTags, },
    '/resource/(\d+)/tag/([\w.:_\-]+)' => { DELETE => \&_deleteTag, },
    '/resource/(\d+)/booking/(\d+)'    => {
        GET    => \&_retrieveBooking,
        POST   => \&_updateBooking,
        DELETE => \&_deleteBooking,
    },
    '/resource/(\d+)/booking/(\d+)/ical' =>
        { GET => \&_retrieveBookingIcal },
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
            send_error(HTTP_METHOD_NOT_ALLOWED);
        }
    }
    else {

        # Requested URL not available
        send_error(HTTP_NOT_FOUND);
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
    if ( open my $dtd, "<", "dtd/$id.dtd" ) {

        # slurp dtd file
        local $/;
        _reply( HTTP_OK, 'text/sgml', <$dtd> );
    }
    else {
        send_error(HTTP_BAD_REQUEST);
    }
}


sub _listBookingsIcal {
    listBookings( @_, "ical" );
}

sub _createBooking {
    my ( $cgi, $idResource ) = @_;

    if ( !defined $idResource ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $b = Smeagol::Booking->from_xml( $cgi->param('POSTDATA') );
    if ( !defined $b ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $ag = $r->agenda;

    if ( $ag->interlace($b) ) {
        my $overlapping_agenda = Smeagol::Agenda->new();
        my @overlapping = grep { $_->intersects($b) } $ag->elements;
        foreach my $aux (@overlapping) {
            $overlapping_agenda->append($aux);
        }

        send_xml( $overlapping_agenda->to_xml( $r->url, 1 ),
            status => HTTP_CONFLICT );
        return;
    }

    $r->agenda->append($b);
    $r->save();
    send_xml( $b->to_xml( $r->url, 1 ), status => HTTP_CREATED );
}

sub _retrieveBooking {
    my ( $cgi, $idR, $idB, $viewAs ) = @_;

    if ( !defined $idR || !defined $idB ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ics = $b->ical->calendar->as_string;
        send_ical($ics);
    }
    else {
        send_xml( $b->to_xml( $r->url, 1 ) );
    }
}

sub _retrieveBookingIcal {
    _retrieveBooking( @_, "ical" );
}

sub _deleteBooking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    $ag->remove($b);
    $r->save();
    send_error( HTTP_OK, "Booking #$idB deleted" );
}

# NOTE: No race conditions in _updateBooking, because
#       we're using HTTP::Server::Simple which has no
#       concurrence management (requests are served
#       sequentially)
sub _updateBooking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $old_booking = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $old_booking ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $new_booking
        = Smeagol::Booking->from_xml( $cgi->param('POSTDATA'), $idB );

    if ( !defined $new_booking ) {
        send_error(HTTP_BAD_REQUEST);
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

        send_xml( $overlapping_agenda->to_xml( $r->url, 1 ),
            status => HTTP_CONFLICT );
        return;
    }

    $ag->append($new_booking);
    $r->agenda($ag);
    $r->save();

    send_xml( $new_booking->to_xml( $r->url, 1 ) );
    return;
}

sub _createTag {
    my ( $cgi, $idResource ) = @_;
    if ( !defined $idResource ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $tg = Smeagol::Tag->from_xml( $cgi->param('POSTDATA') );
    if ( !defined $tg ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    $r->tags->append($tg);
    $r->save();
    send_xml( $tg->toXML( $r->url, 1 ), status => HTTP_CREATED );
}

sub _listTags {
    my ( $cgi, $idResource ) = @_;
    my $r = Smeagol::Resource->load($idResource);

    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }
    my $xml = $r->tags->to_xml( $r->url, 1 );
    send_xml($xml);
}

sub _deleteTag {
    my ( $cgi, $idR, $idT ) = @_;

    if ( !defined $idR || !defined $idT ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $tgS = $r->tags;
    if ( !defined $tgS ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    my $tg = ( grep { $_->value eq $idT } $tgS->elements )[0];
    if ( !defined $tg ) {
        send_error(HTTP_NOT_FOUND);
        return;
    }

    $tgS->remove($tg);
    $r->save();
    send_error( HTTP_OK, "Tag #$idT deleted" );
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
    if ( open my $css, "<", "css/$id.css" ) {

        # slurp css file
        local $/;
        _reply( HTTP_OK, 'text/css', <$css> );
    }
    else {
        send_error(HTTP_BAD_REQUEST);
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
    if ( open my $xsl, "<", "xsl/$id.xsl" ) {

        # slurp css file
        local $/;
        _reply( HTTP_OK, 'application/xml', <$xsl> );
    }
    else {
        send_error(HTTP_BAD_REQUEST);
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
        _reply( HTTP_OK, 'text/html; charset=UTF-8', <$html> );
    }
    else {
        send_error(HTTP_BAD_REQUEST);
    }
}

1;
