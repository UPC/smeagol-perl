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

    my $bless = {	url => $url,
					ua => $ua,
				};

    bless $bless, $class;
}

sub listResources {
    my $self = shift;
    my $res = $self->{ua}->get($self->{url}."/resources");
	my @idResources;

	if( $res->status_line =~ /200/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		for my $resNode ( $dom->getElementsByTagName('resource')){
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
    my $req = HTTP::Request->new( POST => $self->{url}."/resource" );
    $req->content_type('text/xml');
    $req->content($res_xml);

    my $res = $self->{ua}->request($req);

	if( $res->status_line =~ /201/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		return $dom->getElementsByTagName('resource')->get_node(1)->getAttribute('xlink:href');
	}else{
		return undef;
	}
}

sub createAgenda {
	my $self = shift;
	my ($idResource) = @_;

	#XXX De moment no es te en compte que hi hagi mes d'una agenda per recurs
	#Si es crea una nova agenda, en cas que hi hagi una anterior s'esborrara
	my $resource = getResource($idResource);
	$resource->{idAgenda} = '';
	my $res_xml = XMLout($resource); 	

	my $req = HTTP::Request->new( POST => $self->{url}.$idResource );
    $req->content_type('text/xml');
    $req->content($res_xml);

	my $res = $self->{ua}->request($req);
	if($res->status_line =~ /200/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		return $dom->getElementsByTagName('agenda')->get_node(1)->getAttribute('xlink:href');
	}
	return undef;
}

sub createBooking {
    my $self = shift;
    my ( $idAgenda, @from, @to ) = @_;

    my $req = HTTP::Request->new( POST => $self->{url}.$idAgenda );
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

    my $res = $self->{ua}->request($req);
	if($res->status_line =~ /201/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		return $dom->getElementsByTagName('booking')->get_node(1)->getAttribute('xlink:href');
	}
    return undef;
}

sub getResource {
    my $self = shift;
    my ($idResource) = @_;

    my $res = $self->{ua}->get($self->{url}.$idResource);

	#FIXME: Cal controlar el cas que si/no hi hagi agenda
	if($res->status_line =~ /200/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		my $resource = XMLin($res->content);
		if(defined $resource->{idAgenda}){
			$resource->{agenda} = $dom->getElementsByTagName('agenda')->get_node(1)->getAttribute('xlink:href');
		}
		return $resource;
	}
	return undef;
}

sub getAgenda {
    my $self = shift;
    my ($idAgenda) = @_;

    my $res = $self->{ua}->get($self->{url}.$idAgenda);
	my @bookings;

	if($res->status_line =~ /200/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		for my $booksNode ( $dom->getElementsByTagName('booking')){
			push @bookings, $booksNode->get_node(1)->getAttribute('xlink:href');
		}
	}
	return undef;
}

sub getBooking {
    my $self = shift;
    my ( $idBooking ) = @_;

    my $res = $self->{ua}->get($self->{url}.$idBooking);

	if($res->status_line =~ /200/){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		return XMLin($dom->getElementsByTagName('booking'));
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
    my $req = HTTP::Request->new( POST => $self->{url}.$idResource );

    $req->content_type('text/xml');
    $req->content($res_xml);

    my $res = $self->{ua}->request($req);

	if($res->status_line =~ /200/){
		my $xml = $res->content;
		if($xml !~ /xmlns:xlink/ ){
			$xml =~ s/<resource /<resource xmlns:xlink=\"http:\/\/www.w3.org\/1999\/xlink\ "/; 
    	}
		my $dom = eval {XML::LibXML->new->parse_string($xml)};
		return $dom->getElementsByTagName('resource')->get_node(1)->getAttribute('xlink:href');
	}
    return undef;
}

sub updateAgenda {
    my $self = shift;
    return @_;
}

sub updateBooking {
    my $self = shift;
    my ( $idBooking, @from, @to ) = @_;
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

    my $req = HTTP::Request->new( POST => $self->{url}.$idBooking );
    $req->content_type('text/xml');
    $req->content($booking_xml);

    my $res = $self->{ua}->request($req);
	if($res->status_line =~ /200/ ){
		my $dom = eval {XML::LibXML->new->parse_string($res->content)};
		return $dom->getElementsByTagName('booking')->get_node(1)->getAttribute('xlink:href');
	}
    return undef;
}

sub delResource {
    my $self = shift;
    my ($idResource) = @_;
    my $req  = HTTP::Request->new( DELETE => $self->{url}.$idResource );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
	if($res->status_line =~ /200/ ){
		return $idResource;
	}
    return undef;
}

sub delAgenda {
    my $self = shift;
    my ($idAgenda) = @_;
    my $req  = HTTP::Request->new( DELETE => $self->{url}.$idAgenda );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
	if($res->status_line =~ /200/ ){
		return $idAgenda;
	}
    return undef;
}

sub delBooking {
    my $self = shift;
    my ($idBooking) = @_;
    my $req  = HTTP::Request->new( DELETE => $self->{url}.$idBooking );
    $req->content_type('text/xml');

    my $res = $self->{ua}->request($req);
	if($res->status_line =~ /200/ ){
		return $idBooking;
	}
    return undef;
}

1;
