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
use Data::Dumper;

our @EXPORT_OK
    = qw(listResources retrieveResource deleteResource updateResource createResource listBookings listBookingsIcal createBooking createTag listTags deleteTag retrieveBooking updateBooking deleteBooking retrieveBookingIcal);

############
# Handlers #
############

sub listResources {
    my $list = Smeagol::Resource::List->new();
    Smeagol::Server::sendXML( $list->toXML("/resources") );
}

sub retrieveResource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($id);

    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
    }
    else {
        Smeagol::Server::sendXML( $r->toXML("") );
    }
}

sub deleteResource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($id);

    if ( !defined $r ) {
        Smeagol::Server::sendError( HTTP_NOT_FOUND,
            "Resource #$id does not exist" );
    }
    else {
        $r->remove();
        Smeagol::Server::sendError( HTTP_OK, "Resource #$id deleted" );
    }
}

sub updateResource {
    my ( $cgi, $id ) = @_;

    if ( !defined $id ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $updatedResource
        = Smeagol::Resource->newFromXML( $cgi->param('POSTDATA'), $id );

    if ( !defined $updatedResource ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
    }
    elsif ( !defined Smeagol::Resource->load($id) ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
    }
    else {
        $updatedResource->save();
        Smeagol::Server::sendXML( $updatedResource->toXML("") );
    }
}

sub createResource {
    my ($cgi) = @_;

    # FIXME: hack to get rid of namespace attribute generation problems
    my $xml = Smeagol::XML->removeXLink( $cgi->param('POSTDATA') );

    # end FIXME

    my $r = Smeagol::Resource->newFromXML($xml);

    if ( !defined $r ) {    # wrong XML argument
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
    }
    else {
        $r->save();

        # FIXME: Sending relative URI in "Location:" header.
        #        Conforming HTTP standars, location should be an absolute URI.
        Smeagol::Server::reply(
            status  => HTTP_CREATED,
            headers => [ 'Location: /resource/' . $r->id, ],
        );
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
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ical = $r->agenda->ical;
        Smeagol::Server::sendICal("$ical");
    }
    else {
        my $xml = $r->agenda->toXML( $r->url );
        Smeagol::Server::sendXML($xml);
    }
}

sub listBookingsIcal {
    listBookings( @_, "ical" );
}

sub createBooking {
    my ( $cgi, $idResource ) = @_;

    if ( !defined $idResource ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $b = Smeagol::Booking->newFromXML(
        Smeagol::XML->removeXLink( $cgi->param('POSTDATA') ) );
    if ( !defined $b ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $ag = $r->agenda;

    if ( $ag->interlace($b) ) {
        my $overlappingAgenda = Smeagol::Agenda->new();
        my @overlapping = grep { $_->intersects($b) } $ag->elements;
        foreach my $aux (@overlapping) {
            $overlappingAgenda->append($aux);
        }

        Smeagol::Server::sendXML( $overlappingAgenda->toXML( $r->url ),
            status => HTTP_CONFLICT );
        return;
    }

    $r->agenda->append($b);
    $r->save();
    Smeagol::Server::sendXML( $b->toXML( $r->url ), status => HTTP_CREATED );
}

sub createTag {
    my ( $cgi, $idResource ) = @_;
    if ( !defined $idResource ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idResource);
    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $tg = Smeagol::Tag->newFromXML(
        Smeagol::XML->removeXLink( $cgi->param('POSTDATA') ) );
    if ( !defined $tg ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    $r->tags->append($tg);
    $r->save();
    Smeagol::Server::sendXML( $tg->toXML( $r->url ), status => HTTP_CREATED );
}

sub listTags {
    my ( $cgi, $idResource ) = @_;
    my $r = Smeagol::Resource->load($idResource);

    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }
    my $xml = $r->tags->toXML( $r->url );
    Smeagol::Server::sendXML($xml);
}

sub deleteTag {
    my ( $cgi, $idR, $idT ) = @_;

    if ( !defined $idR || !defined $idT ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $tgS = $r->tags;
    if ( !defined $tgS ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $tg = ( grep { $_->value eq $idT } $tgS->elements )[0];
    if ( !defined $tg ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    $tgS->remove($tg);
    $r->save();
    Smeagol::Server::sendError( HTTP_OK, "Tag #$idT deleted" );
}

sub retrieveBooking {
    my ( $cgi, $idR, $idB, $viewAs ) = @_;

    if ( !defined $idR || !defined $idB ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    if ( defined $viewAs && $viewAs eq 'ical' ) {
        my $ics = $b->ical->calendar->as_string;
        Smeagol::Server::sendICal($ics);
    }
    else {
        Smeagol::Server::sendXML( $b->toXML( $r->url ) );
    }
}

# NOTE: No race conditions in updateBooking, because
#       we're using HTTP::Server::Simple which has no
#       concurrence management (requests are served
#       sequentially)
sub updateBooking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);
    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $oldBooking = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $oldBooking ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $newBooking = Smeagol::Booking->newFromXML(
        Smeagol::XML->removeXLink( $cgi->param('POSTDATA') ), $idB );

    if ( !defined $newBooking ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    #
    # Check wether updated booking would produce overlappings
    #
    $ag->remove($oldBooking);

    if ( $ag->interlace($newBooking) ) {

        # if overlappings are produced, let's build a new agenda
        # containing affected bookings and return it to the client
        my @overlapping = grep { $_->intersects($newBooking) } $ag->elements;
        my $overlappingAgenda = Smeagol::Agenda->new();

        foreach my $aux (@overlapping) {
            $overlappingAgenda->append($aux);
        }
        $r->agenda($overlappingAgenda);

        Smeagol::Server::sendXML( $overlappingAgenda->toXML( $r->url ),
            status => HTTP_CONFLICT );
        return;
    }

    $ag->append($newBooking);
    $r->agenda($ag);
    $r->save();

    Smeagol::Server::sendXML( $newBooking->toXML( $r->url ) );
    return;
}

sub deleteBooking {
    my ( $cgi, $idR, $idB ) = @_;

    if ( !defined $idR || !defined $idB ) {
        Smeagol::Server::sendError(HTTP_BAD_REQUEST);
        return;
    }

    my $r = Smeagol::Resource->load($idR);

    if ( !defined $r ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $ag = $r->agenda;
    if ( !defined $ag ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    my $b = ( grep { $_->id eq $idB } $ag->elements )[0];
    if ( !defined $b ) {
        Smeagol::Server::sendError(HTTP_NOT_FOUND);
        return;
    }

    $ag->remove($b);
    $r->save();
    Smeagol::Server::sendError( HTTP_OK, "Booking #$idB deleted" );
}

sub retrieveBookingIcal {
    retrieveBooking( @_, "ical" );
}

1;
