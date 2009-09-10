package Smeagol::Shell;

use strict;
use warnings;

use Smeagol::Client;

use base qw(Term::Shell);

sub run_foo {
  print "foo\n";
}

sub run_crea_recurs{
  my $self = shift;
  my ($desc) = @_;
  print "crear recurs amb les dades següents:\n";
  print "            descripcio: $desc\n";
}
sub smry_crea_recurs { "Crea un recurs senzill sense reserves inicials" }
sub help_crea_recurs { "La descripció és obligatoria, la informació adicional i les etiquetes són opcionals\n"; }

sub msg_unknown_cmd {
  my $self = shift;  
  my ($cmd) = @_;
  print "Comanda '$cmd' desconeguda; escriu 'help' per obtenir ajuda.\n";
}

1;
