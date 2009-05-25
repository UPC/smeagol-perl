package Smeagol::Server::Handler;

use strict;
use warnings;

use base qw(Exporter);
use Smeagol::Server;
use Smeagol::Resource::List;
use Smeagol::Resource;
use Smeagol::Agenda;
use Smeagol::Booking;
use Smeagol::Tag;
use HTTP::Status qw(:constants);

our @EXPORT_OK
    = qw(listResources retrieveResource deleteResource updateResource createResource listBookings listBookingsIcal createBooking createTag listTags deleteTag retrieveBooking updateBooking deleteBooking retrieveBookingIcal);

############
# Handlers #
############

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
        Smeagol::Server::send_error( HTTP_NOT_FOUND,
            "Resource #$id does not exist" );
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

sub listBookingsIcal {
    listBookings( @_, "ical" );
}

sub createBooking {
    my ( $cgi, $idResource ) = @_;

    if ( !defined $idResource ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $b = Smeagol::Booking->from_xml( $cgi->param('POSTDATA') );
    if ( !defined $b ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $ag = $r->agenda;

    if ( $ag->interlace($b) ) {
        my $overlapping_agenda = Smeagol::Agenda->new();
        my @overlapping = grep { $_->intersects($b) } $ag->elements;
        foreach my $aux (@overlapping) {
            $overlapping_agenda->append($aux);
        }

        Smeagol::Server::send_xml( $overlapping_agenda->to_xml( $r->url, 1 ),
            status => HTTP_CONFLICT );
        return;
    }

    $r->agenda->append($b);
    $r->save();
    Smeagol::Server::send_xml( $b->to_xml( $r->url, 1 ),
        status => HTTP_CREATED );
}

sub createTag {
    my ( $cgi, $idResource ) = @_;
    if ( !defined $idResource ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $tg = Smeagol::Tag->from_xml( $cgi->param('POSTDATA') );
    if ( !defined $tg ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    $r->tags->append($tg);
    $r->save();
    Smeagol::Server::send_xml( $tg->toXML( $r->url, 1 ),
        status => HTTP_CREATED );
}

sub listTags {
    my ( $cgi, $idResource ) = @_;
    my $r = Smeagol::Resource->load($idResource);

    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }
    my $xml = $r->tags->to_xml( $r->url, 1 );
    Smeagol::Server::send_xml($xml);
}

sub deleteTag {
    my ( $cgi, $idR, $idT ) = @_;

    if ( !defined $idR || !defined $idT ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $tgS = $r->tags;
    if ( !defined $tgS ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $tg = ( grep { $_->value eq $idT } $tgS->elements )[0];
    if ( !defined $tg ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    $tgS->remove($tg);
    $r->save();
    Smeagol::Server::send_error( HTTP_OK, "Tag #$idT deleted" );
}

sub retrieveBooking {
    my ( $cgi, $idR, $idB, $viewAs ) = @_;

    if ( !defined $idR || !defined $idB ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ics = $b->ical->calendar->as_string;
        Smeagol::Server::send_ical($ics);
    }
    else {
        Smeagol::Server::send_xml( $b->to_xml( $r->url, 1 ) );
    }
}

# NOTE: No race conditions in updateBooking, because
#       we're using HTTP::Server::Simple which has no
#       concurrence management (requests are served
#       sequentially)
sub updateBooking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $old_booking = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $old_booking ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $new_booking
        = Smeagol::Booking->from_xml( $cgi->param('POSTDATA'), $idB );

    if ( !defined $new_booking ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
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

        Smeagol::Server::send_xml( $overlapping_agenda->to_xml( $r->url, 1 ),
            status => HTTP_CONFLICT );
        return;
    }

    $ag->append($new_booking);
    $r->agenda($ag);
    $r->save();

    Smeagol::Server::send_xml( $new_booking->to_xml( $r->url, 1 ) );
    return;
}

sub deleteBooking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        Smeagol::Server::send_error(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        Smeagol::Server::send_error(HTTP_NOT_FOUND);
        return;
    }

    $ag->remove($b);
    $r->save();
    Smeagol::Server::send_error( HTTP_OK, "Booking #$idB deleted" );
}

sub retrieveBookingIcal {
    retrieveBooking( @_, "ical" );
}

1;
