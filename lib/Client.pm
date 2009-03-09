package Client;

# version -0.01 alfa-alfa-version
use strict;
use warnings;
use DateTime;
use Resource;
use Agenda;
use Booking;
use LWP::UserAgent;
use Carp;
use Data::Dumper;
use XML::LibXML;
use XML::Simple;

my %COMMAND_VALID = map { $_ => 1 } qw( POST GET PUT DELETE );

my $port   = 8000;
my $server = 'localhost';

sub new {
    my $class = shift;
    my ($url) = @_;

    return undef unless defined $url;

    my $ua = LWP::UserAgent->new();
    $ua->agent("SmeagolClient/0.1 ");

    my $bless = {
        url => $url,
        ua  => $ua,
    };

    bless $bless, $class;
}

sub listResources {
    my $self = shift;
    my $res  = $self->{ua}->get( $self->{url} . "/resources" );
    my @idResources;

    if ( $res->status_line =~ /200/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        for my $resNode ( $dom->getElementsByTagName('resource') ) {
            my $idRes = $resNode->getAttribute('xlink:href');
            push @idResources, $idRes;
        }
        return @idResources;
    }
    return undef;

}

sub createResource {
    my $self = shift;
    my ( $des, $gra ) = @_;

    my $res_xml = "<resource>
					<description>$des</description>
					<granularity>$gra</granularity>
					</resource>";
    my $req = HTTP::Request->new( POST => $self->{url} . "/resource" );
    $req->content_type('text/xml');
    $req->content($res_xml);

    my $res = $self->{ua}->request($req);

    if ( $res->status_line =~ /201/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        return $dom->getElementsByTagName('resource')->get_node(1)
            ->getAttribute('xlink:href');
    }
    else {
        return undef;
    }
}

sub createBooking {
    my $self = shift;
    my ( $idR, $from, $to ) = @_;

    my $req = HTTP::Request->new( POST => $self->{url} . '/resource/' .  $idR . '/booking' );
    $req->content_type('text/xml');
    my $booking_xml = "<booking>
						<from>
							<year>".$from->{year}."</year>
							<month>".$from->{month}."</month>
							<day>".$from->{day}."</day>
							<hour>".$from->{hour}."</hour>
							<minute>".$from->{minute}."</minute>
							<second>".$from->{second}."</second>
						</from>
						<to>
							<year>".$to->{year}."</year>
							<month>".$to->{month}."</month>
							<day>".$to->{day}."</day>
							<hour>".$to->{hour}."</hour>
							<minute>".$to->{minute}."</minute>
							<second>".$to->{second}."</second>
						</to>
					</booking>";
    $req->content($booking_xml);

    my $res = $self->{ua}->request($req);

    if ( $res->status_line =~ /201/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        return $dom->getElementsByTagName('booking')->get_node(1)
            ->getAttribute('xlink:href');
    }
    return undef;
}

sub getResource {
    my $self = shift;
    my ($id) = @_;

    my $res = $self->{ua}->get( $self->{url} . '/resource/' . $id );

    #FIXME: Cal controlar el cas que si/no hi hagi agenda
    if ( $res->status_line =~ /200/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        my $resource = XMLin( $res->content );
        if ( defined $resource->{idAgenda} ) {
            $resource->{agenda}
                = $dom->getElementsByTagName('agenda')->get_node(1)
                ->getAttribute('xlink:href');
        }
        return $resource;
    }
    return undef;
}

sub getBooking {
    my $self = shift;
    my ($idR, $idB) = @_;

	return undef unless (defined $idB || defined $idR);

    my $res = $self->{ua}->get( $self->{url} . '/resource/' . $idR . '/booking/' . $idB );

    if ( $res->status_line =~ /200/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        return XMLin( $res->content );
    }
    return undef;
}

sub listBookings { 
	my $self = shift;
	my ($id) = @_;

	my $res = $self->{ua}->get( $self->{url} . '/resource/' . $id . '/bookings' );

	my @bookings;

	if ( $res->status_line =~ /200/ ) {
		my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
		for my $booksNode ( $dom->getElementsByTagName('booking') ) {
			push @bookings, $booksNode->getAttribute('xlink:href');
		}
		return @bookings;
	}
	return undef;
}

sub updateResource {
    my $self = shift;
    my ( $idResource, $des, $gra ) = @_;

    my $res_xml = "<resource>
					<description>$des</description>
					<granularity>$gra</granularity>
					</resource>";
    my $req = HTTP::Request->new( POST => $self->{url} . '/resource/'.$idResource );

    $req->content_type('text/xml');
    $req->content($res_xml);

    my $res = $self->{ua}->request($req);

    if ( $res->status_line =~ /200/ ) {
        my $xml = $res->content;
        if ( $xml !~ /xmlns:xlink/ ) {
            $xml
                =~ s/<resource /<resource xmlns:xlink=\"http:\/\/www.w3.org\/1999\/xlink\ "/;
        }
        my $dom = eval { XML::LibXML->new->parse_string($xml) };
        return $dom->getElementsByTagName('resource')->get_node(1)
            ->getAttribute('xlink:href');
    }
    return undef;
}

sub updateBooking {
	my $self = shift;
	my ( $idR, $idB, $from, $to ) = @_;
    
	my $booking_xml = "<booking>
						<from>
							<year>".$from->{year}."</year>
							<month>".$from->{month}."</month>
							<day>".$from->{day}."</day>
							<hour>".$from->{hour}."</hour>
							<minute>".$from->{minute}."</minute>
							<second>".$from->{second}."</second>
						</from>
						<to>
							<year>".$to->{year}."</year>
							<month>".$to->{month}."</month>
							<day>".$to->{day}."</day>
							<hour>".$to->{hour}."</hour>
							<minute>".$to->{minute}."</minute>
							<second>".$to->{second}."</second>
						</to>
					</booking>";

    my $req = HTTP::Request->new( POST => $self->{url} . '/resource/' . $idR . '/booking/' . $idB );
    $req->content_type('text/xml');
    $req->content($booking_xml);

    my $res = $self->{ua}->request($req);
    if ( $res->status_line =~ /200/ ) {
        my $dom = eval { XML::LibXML->new->parse_string( $res->content ) };
        return $dom->getElementsByTagName('booking')->get_node(1)
            ->getAttribute('xlink:href');
    }
    return undef;
}

sub delResource {
    my $self = shift;
    my ($id) = @_;

    my $req = HTTP::Request->new( DELETE => $self->{url} . '/resource/' .  $id );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
    if ( $res->status_line =~ /200/ ) {
        return $id;
    }
    return undef;
}

sub delBooking {
    my $self = shift;
    my ($idR, $idB) = @_;

	return unless (defined $idB || defined $idR);

    my $req = HTTP::Request->new( DELETE => $self->{url} . '/resource/' . $idR . '/booking/' . $idB );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
    if ( $res->status_line =~ /200/ ) {
        return $idB;
    }
    return undef;
}

1;
