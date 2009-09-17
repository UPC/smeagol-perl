package Smeagol::Shell;

use strict;
use warnings;

use Data::Dumper;
use Smeagol::Client;
use Smeagol::Server;
use Smeagol::DataStore;

use base qw(Term::Shell);
our $pid;
our $client;
our $idResource;

sub init {
  my $self = shift;
  my $serverPort = 8000;
  my $server     = "http://localhost:$serverPort";
  $pid        = Smeagol::Server->new($serverPort)->background();
  $client = Smeagol::Client->new($server);
  Smeagol::DataStore::init();
}

####LISTAR RECURSOS
sub run_llista_recursos{
  my $self = shift;
  my @res = $client->listResources();
  foreach(@res){
    print " $_\n";
  }
}

sub smry_llista_recursos { "Selecciona un recurs d'entre tots els existents. Aquest serà escollit per realitzar accions relacionades amb ell" }
sub help_llista_recursos { "()\n"; }
sub comp_llista_recursos {
  my $self = shift;
}

####CREA RECURS
sub run_crea_recurs{
  my $self = shift;
  my ($desc) = @_;
  if(!defined $desc){
	print "ERROR: Cal incloure una descripcio\n";
  }else{
  	my $res = $client->createResource($desc);
    print " $res\n";
  }
}

sub smry_crea_recurs { "Crea un recurs senzill sense reserves inicials" }
sub help_crea_recurs { "La descripció és obligatoria, la informació adicional i les etiquetes són opcionals\n"; }
sub comp_crea_recurs {
  my $self = shift;
}

####TRIAR RECURS
sub run_tria_recurs{
  my $self = shift;
  my ($id) = @_;
  if(!defined $id){
	print "ERROR: Cal introduir un identificador d'un recurs\n";
  }else{
    my $res = $client->getResource($id);
    if(!defined $res){
      print "Identificador incorrecte. Recurs amb identificador \"$id\" no seleccionat\n";
      if(defined $idResource){
        print " De moment queda triat el recurs $idResource\n"
      }else{
        print " No hi ha cap recurs triat de moment\n"
      }
    }else{
	  $idResource = $id;
      print "Recurs $idResource triat correctament\n";
    }
  }
}

sub smry_tria_recurs { "Selecciona un recurs d'entre tots els existents. Aquest serà escollit per realitzar accions relacionades amb ell" }
sub help_tria_recurs { "()\n"; }
sub comp_tria_recurs { my $self = shift;}

####CONSULTA RECURS
sub run_consulta_recurs{
  my $self = shift;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }else{
    my $res = $client->getResource($idResource);
    my @tags = $client->listTags($idResource);
    print "Recurs $idResource\n  Descripcio: $res->{description}\n  Tags: \n";
    foreach(@tags){
	  print "      $_\n";
    }
	print "\n";
  }
}

sub smry_consulta_recurs { "Mostra les dades del recurs escollit" }
sub help_consulta_recurs { "Abans de poder consultar un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\")\n"; }
sub comp_consulta_recurs { my $self = shift;}

####ESBORRAR RECURS
#Al'hora d'esborrar s'ha de posar $idResource=undef
sub run_esborra_recurs{
  my $self = shift;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }else{
    my $res = $client->delResource($idResource);
    if(!defined $res){
	    print "ERROR: No s'ha esborrat cap recurs\n";
    }else{
	  print "Recurs $idResource esborrat correctament!\n";
      $idResource = undef;
	}
  }
}

sub smry_esborra_recurs { "Esborra un recurs" }
sub help_esborra_recurs { "Abans de poder esborrar un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\")\n"; }
sub comp_esborra_recurs {
  my $self = shift;
}

####AFEGIR ETIQUETA
sub run_afegeix_etiqueta{
  my $self = shift;
  my ($tag) = @_;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }elsif($tag){
    my $res = $client->createTag($idResource, $tag);
    if(defined $res){
      print "Etiqueta afegida $res correctament!\n";
	}else{
      print "No s'ha pogut afegir correctament\n";
	}
  }else{
    print "ERROR: No hi ha cap etiqueta introduïda.\n";
  }
}

sub smry_afegeix_etiqueta { "Afegeix una etiqueta pel recurs escollit" }
sub help_afegeix_etiqueta { "Abans de poder afegir una etiqueta a un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\"). Una etiqueta ha de tenir entre 2 i 60 caràcters i només pot contenir lletres, números, '.', ':', '_' i '-' \n"; }
sub comp_afegeix_etiqueta { my $self = shift;}



####COMANDA DESCONEGUDA
sub msg_unknown_cmd {
  my $self = shift;  
  my ($cmd) = @_;
  print "Comanda '$cmd' desconeguda; escriu 'help' per obtenir ajuda.\n";
}

sub run_exit{
  my $self = shift;
  kill 3, $pid;
  $self->stoploop();
}

1;
