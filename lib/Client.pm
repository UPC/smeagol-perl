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

my %COMMAND_VALID = map { $_ => 1 } qw( POST GET PUT DELETE );

my $port   = 8000;
my $server = 'localhost';

sub new {
    my $class = shift;

    my $bless = {};

    bless $bless, $class;
}

sub _client_call {
    my ( $server, $url, $port, $command ) = @_;
    $port    ||= 80;
    $command ||= "GET";

    croak "Error: Invalid Command '$command'" unless $COMMAND_VALID{$command};

    # Create a user agent object
    my $ua = LWP::UserAgent->new;
    $ua->agent("SmeagolClient/0.1 ");

    # Create a request
    my $req = HTTP::Request->new( $command => "http://$server:$port/$url" );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ( $res->is_success ) {
        print $res->content;
    }
    else {
        print $res->status_line, "\n";
    }

}

###RESOURCE MAINTENANCE
sub list_resources {
    my $self = shift;

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("http://$server:$port/resources");

    return
        wantarray ? ( $res->status_line, $res->content ) : $res->status_line;
}

sub create_resource {
    my $self = shift;
    my ( $id, $des, $gra ) = @_;
	
	my $res_xml = "<resource>
					<id>$id</id>
					<description>$des</description>
					<granularity>$gra</granularity>
					</resource>";
    my $req = HTTP::Request->new( POST => "http://$server:$port/resource");
    $req->content_type('text/xml');
    $req->content($res_xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res->status_line;
}

sub retrieve_resource {
    my $self = shift;
    my ($id) = @_;

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get( "http://$server:$port/resource/$id" );

    return
        wantarray ? ( $res->status_line, $res->content ) : $res->status_line;

}

sub delete_resource {
    my $self = shift;
    my ($id) = @_;
    my $req  = HTTP::Request->new(
        DELETE => "http://$server:$port/resource/" . $id );
    $req->content_type('text/xml');

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res->status_line;
}

sub update_resource {
    my $self = shift;
    my ( $id, $des, $gra ) = @_;
	
	my $res_xml = "<resource>
					<id>$id</id>
					<description>$des</description>
					<granularity>$gra</granularity>
					</resource>";
    my $req = HTTP::Request->new( PUT => "http://$server:$port/resource/$id");
    $req->content_type('text/xml');
    $req->content($res_xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res->status_line;
}


###BOOKING MAINTENANCE

sub list_bookings_resource {
    my $self = shift;
	my ($id) = @_;

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get("http://$server:$port/resource/$id/booking");

    return
        wantarray ? ( $res->status_line, $res->content ) : $res->status_line;
}

sub create_booking_resource {
    my $self = shift;
    my ( $id, @from, @to ) = @_;

    my $req = HTTP::Request->new( POST => "http://$server:$port/resource/$id/booking" );
    $req->content_type('text/xml');
    my $booking_xml = "<booking>
						<from>
							<year>$from[0]</year>
							<month>$from[1]</month>
							<day>$from[2]</day>
							<hour>$from[3]</hour>
							<minute>$from[4]</minute>
							<second>$from[5]</second>
						</from>
						<to>
							<year>$to[0]</year>
							<month>$to[1]</month>
							<day>$to[2]</day>
							<hour>$to[3]</hour>
							<minute>$to[4]</minute>
							<second>$to[5]</second>
						</to>
					</booking>";
    $req->content($booking_xml);

    my $ua  = LWP::UserAgent->new();    #Client
    my $res = $ua->request($req);

    return $res->status_line;
}


sub create_booking {
    my $self = shift;
    my ( @from, @to ) = @_;

    my $req = HTTP::Request->new( POST => "http://$server:$port/booking" );
    $req->content_type('text/xml');
    my $booking_xml = "<booking>
						<from>
							<year>$from[0]</year>
							<month>$from[1]</month>
							<day>$from[2]</day>
							<hour>$from[3]</hour>
							<minute>$from[4]</minute>
							<second>$from[5]</second>
						</from>
						<to>
							<year>$to[0]</year>
							<month>$to[1]</month>
							<day>$to[2]</day>
							<hour>$to[3]</hour>
							<minute>$to[4]</minute>
							<second>$to[5]</second>
						</to>
					</booking>";
    $req->content($booking_xml);

    my $ua  = LWP::UserAgent->new();    #Client
    my $res = $ua->request($req);

    return $res->status_line;
}

sub retrieve_booking {
    my $self = shift;
    my ($id) = @_;

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->get( "http://$server:$port/booking/$id");

    return
        wantarray ? ( $res->status_line, $res->content ) : $res->status_line;
}

sub delete_booking {
    my $self = shift;
    my ($id) = @_;
    my $req  = HTTP::Request->new(
        DELETE => "http://$server:$port/booking/$id" );
    $req->content_type('text/xml');

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res->status_line;
}

sub update_booking {
    my $self = shift;
    my ( $id, @from, @to ) = @_;
	my $booking_xml = "<booking>
						<from>
							<year>$from[0]</year>
							<month>$from[1]</month>
							<day>$from[2]</day>
							<hour>$from[3]</hour>
							<minute>$from[4]</minute>
							<second>$from[5]</second>
						</from>
						<to>
							<year>$to[0]</year>
							<month>$to[1]</month>
							<day>$to[2]</day>
							<hour>$to[3]</hour>
							<minute>$to[4]</minute>
							<second>$to[5]</second>
						</to>
					</booking>";
	
    my $req = HTTP::Request->new( PUT => "http://$server:$port/resource/$id");
    $req->content_type('text/xml');
    $req->content($booking_xml);

    my $ua  = LWP::UserAgent->new();
    my $res = $ua->request($req);

    return $res->status_line;
}


1;