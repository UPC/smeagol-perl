package Smeagol::Shell;

use strict;
use warnings;

use Smeagol::Client;

use base qw(Term::Shell);
our $client;
our $resource;

sub init {
  my $self = shift;
  my $serverPort = 8000;
  my $server     = "http://localhost:$serverPort";
  $client = Smeagol::Client->new($server);
}

sub run_crea_recurs{
  my $self = shift;
  my ($desc) = @_;
  print "ERROR: Cal incloure una descripcio\n" if (!defined $desc);
  my $resource = $client->createResource($desc);
  print " $resource\n";
}

sub smry_crea_recurs { "Crea un recurs senzill sense reserves inicials" }
sub help_crea_recurs { "La descripció és obligatoria, la informació adicional i les etiquetes són opcionals\n"; }
sub comp_crea_recurs {
  my $self = shift;
}

sub run_llista_recursos{
  my $self = shift;
  my @res = $client->listResources();
  foreach(@res){
    print " $_\n";
  }
}

sub smry_llista_recursos { "Llista tots els recursos existents" }
sub help_llista_recursos { "()\n"; }
sub comp_llista_recursos {
  my $self = shift;
}


sub msg_unknown_cmd {
  my $self = shift;  
  my ($cmd) = @_;
  print "Comanda '$cmd' desconeguda; escriu 'help' per obtenir ajuda.\n";
}

1;
