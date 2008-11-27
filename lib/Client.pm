package Client;

# version -0.01 alfa-alfa-version 
use strict;
use warnings;

use Carp;

my %COMMAND_VALID = map { $_ => 1 } qw( POST GET PUT DELETE );

use LWP::UserAgent;

sub _client_call {
  my ($server,$url,$port,$command ) = @_;
	$port ||=80;
	$command ||= "GET";

	carp "Error: Invalid Command '$command'";
  # Create a user agent object
  my $ua = LWP::UserAgent->new;
  $ua->agent("SmeagolClient/0.1 ");

  # Create a request
  my $req = HTTP::Request->new($command => "http://$server:$port/$url");

  # Pass request to the user agent and get a response back
  my $res = $ua->request($req);

  # Check the outcome of the response
  if ($res->is_success) {
      print $res->content;
  }
  else {
      print $res->status_line, "\n";
  }

}

sub new {
    my $class = shift;

    my $client = $class->SUPER::new(@_);

    bless $client, $class;
}

1;
