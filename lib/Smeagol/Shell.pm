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
  $self->run_connecta();
}

####CONNECTA
sub run_connecta {
  my $self = shift;
  my ($server) = @_;
  $server = "http://abydos.ac.upc.edu:8000" if (!defined $server);
  $client = Smeagol::Client->new($server);
  print "Connexió creada amb $server correctament!\n" if (ref $client eq 'Smeagol::Client');
  print "No s'ha pogut establir connexió amb $server!\n" if (ref $client ne 'Smeagol::Client');
}
sub smry_connecta { "Estableix connexió amb un servidor smeagol" }
sub help_connecta { "Cal introduir l'adreça del servidor, p.e. connecta http://localhost:8000 .\nSi no s'introdueix cap adreça es posa per defecte la del servidor de proves http://abydos.ac.upc.edu:8000\n"; }

####LISTAR RECURSOS
sub run_llista_recursos{
  my $self = shift;
  if(defined $client){
	my $idAux = $idResource;
    my @res = $client->listResources();
    foreach(@res){
      $idResource=_idResource($_);
      $self->run_mostra_recurs();
      print "------------------------------------\n";
    }
    $idResource = $idAux;
  }else{
    print "ERROR: No es poden llistar els recursos, no hi ha connexió amb cap servidor smeagol\n";
  }
}

sub smry_llista_recursos { "Llista tots els recursos existents i mostra les seves dades" }
sub help_llista_recursos { "Abans de poder llistar els recursos, cal que s'hagi connectat a un servidor smeagol previament (veure comanda connecta)\n"; }
sub comp_llista_recursos {
  my $self = shift;
}

####CREA RECURS
sub run_crea_recurs{
  my $self = shift;
  my ($desc) = @_;
  if(defined $client){
    if(!defined $desc){
      print "ERROR: Cal incloure una descripcio\n";
    }else{
      my $res = $client->createResource($desc);
	  if(defined $res){
        print "Recurs creat correctament! Dades del recurs:\n";
        print "Identificador: ". _idResource($res)."\n";
        print "Descripció   : $desc \n";
	  }else{
        print "ERROR: El recurs no s'ha pogut crear correctament\n";
	  }
    }
  }else{
    print "ERROR: No es pot crear un recurs, no hi ha connexió amb cap servidor smeagol\n";
  }
}

sub smry_crea_recurs { "Crea un recurs senzill amb una descripció" }
sub help_crea_recurs { "Abans de poder crear un recurs, cal que s'hagi connectat a un servidor smeagol previament (veure comanda connecta)\nLa descripció és obligatoria\n"; }
sub comp_crea_recurs {
  my $self = shift;
}

####TRIAR RECURS
sub run_tria_recurs{
  my $self = shift;
  my ($id) = @_;
  if(defined $client){
    if(!defined $id){
      print "ERROR: Cal introduir un identificador d'un recurs\n";
    }else{
      my $res = $client->getResource($id);
      if(!defined $res){
        print "ERROR: Identificador incorrecte. Recurs amb identificador $id no seleccionat\n";
        if(defined $idResource){
          print "       De moment queda triat el recurs $idResource\n"
        }else{
          print "       No hi ha cap recurs triat de moment\n"
        }
      }else{
        $idResource = $id;
        print "Recurs $idResource triat correctament\n";
      }
    }
  }else{
    print "ERROR: No es pot triar un recurs, no hi ha connexió amb cap servidor smeagol\n";
  }
}
sub smry_tria_recurs { "Selecciona un recurs d'entre tots els existents. Aquest serà escollit per realitzar accions relacionades amb ell" }
sub help_tria_recurs { "()\n"; }
sub comp_tria_recurs { my $self = shift;}


####DESTRIAR RECURS
sub run_destria_recurs{
  my $self = shift;
  if(defined $client){
    $idResource = undef;
  }else{
    print "ERROR: No es pot triar un recurs, no hi ha connexió amb cap servidor smeagol\n";
  }
}
sub smry_destria_recurs { "Deselecciona un recurs previament triat." }
sub help_destria_recurs { "()\n"; }
sub comp_destria_recurs { my $self = shift;}

####MOSTRAR RECURS
sub run_mostra_recurs{
  my $self = shift;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }else{
    my $res = $client->getResource($idResource);
    print "Dades del recurs $idResource\nDescripcio: $res->{description}\n";
    $self->run_mostra_etiquetes();
    $self->run_mostra_reserves();
  }
}

sub smry_mostra_recurs { "Mostra les dades del recurs escollit" }
sub help_mostra_recurs { "Abans de poder mostrar un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\")\n"; }
sub comp_mostra_recurs { my $self = shift;}

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
	  my @ids = _idResourceTag($res);
      print "Etiqueta ".$ids[1]." afegida al recurs ".$ids[0]." correctament!\n";
	}else{
      print "ERROR: No s'ha pogut afegir correctament\n";
	}
  }else{
    print "ERROR: No hi ha cap etiqueta introduïda.\n";
  }
}
sub smry_afegeix_etiqueta { "Afegeix una etiqueta pel recurs escollit" }
sub help_afegeix_etiqueta { "Abans de poder afegir una etiqueta a un recurs, cal que aquest hagi estat triat previament (veure comanda tria_recurs \"identificador\"). Una etiqueta ha de tenir entre 2 i 60 caràcters i només pot contenir lletres, números, '.', ':', '_' i '-' \n"; }
sub comp_afegeix_etiqueta { my $self = shift;}

####ESBORRAR ETIQUETA
sub run_esborra_etiqueta{
  my $self = shift;
  my ($tag) = @_;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }elsif($tag){
    my $res = $client->delTag($idResource, $tag);
    if(defined $res){
      print "Etiqueta $res esborrada del recurs $idResource correctament!\n";
	}else{
      print "ERROR: No s'ha pogut esborrar l'etiqueta $tag correctament\n";
	}
  }else{
    print "ERROR: No hi ha cap etiqueta introduïda.\n";
  }
}

sub smry_esborra_etiqueta { "Esborra una etiqueta pel recurs escollit" }
sub help_esborra_etiqueta { "Abans de poder esborrar una etiqueta a un recurs, cal que aquest hagi estat triat previament (veure comanda tria_recurs \"identificador\")\n Per esborrar una etiqueta cal introduir el nom d'aquesta\n"; }
sub comp_esborra_etiqueta { my $self = shift;}

####MOSTRAR ETIQUETES
sub run_mostra_etiquetes{
  my $self = shift;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }else{
    my @tags = $client->listTags($idResource);
    print "Etiquetes : ";
    foreach(@tags){
      my @ids = _idResourceTag($_);
	  print $ids[1]."  ";
    }
    print "\n";
  }
}

sub smry_mostra_etiquetes { "Mostra les etiquetes del recurs escollit" }
sub help_mostra_etiquetes { "Abans de poder mostrar les etiquetes d'un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\")\n"; }
sub comp_mostra_etiquetes { my $self = shift;}

####CREAR RESERVA
sub run_crea_reserva{
  my $self = shift;
  my ($desc, $f, $t ) = @_;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }elsif($desc && $f && $t){
    if($f =~ /(\d+)\-(\d+)\-(\d+)\-(\d+):(\d+)/){
      my $from;
      $from->{year}	= $1;
      $from->{month}  = $2;
      $from->{day}    = $3;
      $from->{hour}   = $4;
      $from->{minute} = $5;
      $from->{second} = 01;
      if($t =~ /(\d+)\-(\d+)\-(\d+)\-(\d+):(\d+)/){
        my $to;
        $to->{year}   = $1;
        $to->{month}  = $2;
        $to->{day}    = $3;
        $to->{hour}   = $4;
        $to->{minute} = $5;
        $to->{second} = 00;
        my $res = $client->createBooking($idResource, $desc, $from, $to);
        if(defined $res){
          my @ids = _idResourceBooking($res);
          print "Reserva ".$ids[1]." creada pel recurs ".$ids[0]." correctament!\n";
        }else{
          print "ERROR: No s'ha pogut crear la reserva correctament\n";
	    }
	  }else{
        print "ERROR: Moment de fi amb format incorrecte (veure ajuda comanda crea_reserva)\n";
      }
    }else{
      print "ERROR: Moment d'inici amb format incorrecte (veure ajuda comanda crea_reserva)\n";
    }
  }else{
    print "ERROR: les dades no han estat bé introduides (veure ajuda comanda crea_reserva).\n";
  }
}

sub smry_crea_reserva { "Crea una reserva pel recurs escollit" }
sub help_crea_reserva { "Abans de poder crear una reserva per un recurs, cal que aquest hagi estat triat previament (veure comanda tria_recurs \"identificador\")\nPer esborrar una etiqueta cal introduir una descripcio, un moment d'inici (aaaa-mm-dd-hh:mimi), i un altre de fi\n\tp.e. \"presentació tesis\" 2007-12-01-20:00   2007-12-01-21:00\n"; }
sub comp_crea_reserva { my $self = shift;}


####ESBORRAR RESERVA
sub run_esborra_reserva{
  my $self = shift;
  my ($id) = @_;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }elsif($id){
	my $res = $client->delBooking( $idResource, $id );
    if(defined $res){
      print "Reserva amb identificador $res esborrada del recurs $idResource correctament!\n";
	}else{
      print "ERROR: No s'ha pogut esborrar la reserva $id correctament\n";
	}
  }else{
    print "ERROR: No hi ha cap identificador de reserva introduida.\n";
  }
}

sub smry_esborra_reserva { "Esborra una reserva pel recurs escollit" }
sub help_esborra_reserva { "Abans de poder esborrar una reserva d'un recurs, cal que aquest hagi estat triat previament (veure comanda tria_recurs \"identificador\")\nPer esborrar una reserva cal introduir l'identificador d'aquesta\n"; }
sub comp_esborra_reserva { my $self = shift;}


#### MOSTRA RESERVA
sub run_mostra_reserva{
  my $self = shift;
  my ($id) = @_;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }elsif($id){
    my @bookings = $client->getBooking($idResource, $id);
    foreach(@bookings){
	  print "Identificador: ".$_->{id}."  \n";
	  print "Descripció   : ".$_->{description}."  \n";
	  print "Inici        : ".$_->{from}->{year}."-".$_->{from}->{month}."-".$_->{from}->{day}."-".$_->{from}->{hour}.":".$_->{from}->{minute}."\n";
	  print "Fi           : ".$_->{to}->{year}."-".$_->{to}->{month}."-".$_->{to}->{day}."-".$_->{to}->{hour}.":".$_->{to}->{minute}."\n";
    }
	print "\n";
  }else{
    print "ERROR: No hi ha cap identificador de reserva introduida.\n";
  }
}

sub smry_mostra_reserva { "Mostra les dades d'una reserva" }
sub help_mostra_reserva { "Abans de poder mostrar una reserva d'un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\")\nPer mostrar una reserva cal introduir l'identificador d'aquesta\n"; }
sub comp_mostra_reserva { my $self = shift;}

####MOSTRAR RESERVES
sub run_mostra_reserves{
  my $self = shift;
  if(!defined $idResource){
    print "ERROR: No hi ha recurs triat.\n";
  }else{
    my @bookings = $client->listBookings($idResource);
    print "Reserves  : \n";
    foreach(@bookings){
      my @ids = _idResourceBooking($_);
      $self->run_mostra_reserva($ids[1]);
    }
  }
}

sub smry_mostra_reserves { "Mostra les reserves del recurs escollit" }
sub help_mostra_reserves { "Abans de poder mostrar les reserves d'un recurs, cal que aquest hagi estat triat previament (amb la comanda tria_recurs \"identificador\")\n"; }
sub comp_mostra_reserves { my $self = shift;}


####ALIAS
sub run_surt{
  my $self = shift;
  $self->run_exit(); 
}
sub smry_surt { "Surt del shell" }
sub help_surt { "\n"; }

sub run_ajuda{
  my $self = shift; 
  $self->run_help();
}
sub smry_ajuda { "Mostra ajuda" }
sub help_ajuda { " \n"; }


####COMANDA DESCONEGUDA
sub msg_unknown_cmd {
  my $self = shift;  
  my ($cmd) = @_;
  print "Comanda '$cmd' desconeguda; escriu 'help' per obtenir ajuda.\n";
}


####Metodes interns
sub _idResource {
    my ($url) = shift;

    if ( $url =~ /\/resource\/(\w+)/ ) {
        return $1;
    }
    else {
        return;
    }
}

sub _idResourceBooking {
    my ($url) = shift;

    if ( $url =~ /resource\/(\d+)\/booking\/(\d+)/ ) {
        return ( $1, $2 );
    }
    else {
        return;
    }
}

sub _idResourceTag {
    my ($url) = shift;

    if ( $url =~ /resource\/(\d+)\/tag\/([\w.:_\-]+)/ ) {
        return ( $1, $2 );
    }
    else {
        return;
    }
}

1;
