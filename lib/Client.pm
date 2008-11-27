package Client;

# version -0.01 alfa-alfa-version 
use strict;
use warnings;

my %crud_for = (
    POST   => \&_create_resource,
    GET    => \&_retrieve_resource,
    PUT    => \&_update_resource,
    DELETE => \&_delete_resource,
);

use LWP::UserAgent;

sub _client_call {
    my ($comand, $sub_url) = @_;

  my %resource_by;

  # Create a user agent object
  $ua = LWP::UserAgent->new;
  $ua->agent("MyApp/0.1 ");

  # Create a request
  my $req = HTTP::Request->new($comand => 'http://localhost/'+$sub_url);

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
