package Smeagol::Server::Handler;

use strict;
use warnings;

use base qw(Exporter);
use Smeagol::Server;
use Smeagol::Resource::List;
use Smeagol::Resource;
use Smeagol::Agenda;
use Smeagol::Booking;
use HTTP::Status qw(:constants);

our @EXPORT_OK = qw(listResources retrieveResource deleteResource updateResource createResource listBookings);

##########################
# Handlers for resources #
##########################

sub listResources {
    my $list = Smeagol::Resource::List->new();
    Smeagol::Server::send_xml( $list->to_xml( "/resources", 1 ) );
}

sub retrieveResource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($id);

    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
    }
    else {
        Smeagol::Server::send_xml( $r->to_xml( "", 1 ) );
    }
}

sub deleteResource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($id);

    if ( !defined $r ) {
        Smeagol::Server::send_error( HTTP_NOT_FOUND, "Resource #$id does not exist" );
    }
    else {
        $r->remove();
        Smeagol::Server::send_error( HTTP_OK, "Resource #$id deleted" );
    }
}

sub updateResource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $updated_resource
        = Smeagol::Resource->from_xml( $cgi->param('POSTDATA'), $id );

    if ( !defined $updated_resource ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
    }
    elsif ( !defined Smeagol::Resource->load($id) ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
    }
    else {
        $updated_resource->save();
        Smeagol::Server::send_xml( $updated_resource->to_xml( "", 1 ) );
    }
}

sub createResource {
    my ($cgi) = @_;

    my $r = Smeagol::Resource->from_xml( $cgi->param('POSTDATA') );

    if ( !defined $r ) {    # wrong XML argument
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
    }
    else {
        $r->save();
        Smeagol::Server::send_xml( $r->to_xml( "", 1 ), status => 201 );
    }
}

#########################
# Handlers for bookings #
#########################

#
# FIXME: this call is made as listBookings($cgi, $1, $2, ...);
#        $2 is always undef since this regex captures 1 item only,
#        thus the undef on the args list below.
#        (ticket:115)
#
sub listBookings {
    my ( $cgi, $idResource, undef, $viewAs ) = @_;

    my $r = Smeagol::Resource->load($idResource);

    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ical = $r->agenda->ical;
        Smeagol::Server::send_ical("$ical");
    }
    else {
        my $xml = $r->agenda->to_xml( $r->url, 1 );
        Smeagol::Server::send_xml($xml);
    }
}


1;
