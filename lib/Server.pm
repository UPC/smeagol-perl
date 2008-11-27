package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

use Data::Dumper;

use Resource;
use YAML::Tiny;

my %resource_by;
my $cgi;



sub new {
    my $class = shift;

    my $server = $class->SUPER::new(@_);

    bless $server, $class;
}



sub _reply {
    my ($status, $type, @output) = @_;

    $type = 'text/plain'
        unless defined $type and $type ne '';

    print "HTTP/1.0 $status\n", $cgi->header('-type' => $type), @output, "\n";
}



sub _fail {
    my ($code, $message) = @_;

    my %codes = (
	400 => 'Bad Request',
	403 => 'Forbidden',
	404 => 'Not Found',
        405 => 'Method Not Allowed',
    );

    my $text = $codes{$code} || die "Unknown http code error";
    _reply($code . $text, 'text/plain', $message || $text)
}
       

    


sub _reply_default {
    _fail(404);
}


sub _list_resources {
    my $yaml = YAML::Tiny->new();
    $yaml->[0] = \%resource_by;

    _reply('200 OK', 'text/yaml', $yaml->write_string());
}

sub _create_resource {
    my ($id) = @_;

    $id = $cgi->param('id')
        unless defined $id;
    my $desc = $cgi->param('desc');
    my $gra  = $cgi->param('gra');

    if (defined $id && exists $resource_by{$id}) {
        _fail(403, "Resource #$id already exists!");
    }
    elsif (!defined $id && !defined $desc && !defined $gra) {
        my $resource = Resource->from_xml($cgi->param('POSTDATA'));
        $resource_by{ $resource->{id} } = $resource;
        _reply('201 Created', 'text/plain', "Resource #$resource->{id} created");
    }
    elsif (defined $id && defined $desc && defined $gra) {
        my $resource = Resource->new($id, $desc, $gra);
        $resource_by{ $resource->{id} } = $resource;
        _reply('201 Created', 'text/plain', "Resource #$id created");
    }
    else {
        _fail(400, 'Missing description!');
    }
}

sub _retrieve_resource {
    my ($id) = @_;

    if (!defined $id || !exists $resource_by{$id}) {
        _fail(404);
    }
    else {
        _reply('200 OK', 'text/xml', $resource_by{$id}->to_xml());
    }
}

sub _update_resource {
    _reply_default();
}

sub _delete_resource {
    my ($id) = @_;

    if (!defined $id || !exists $resource_by{$id}) {
        _fail(404);
    }
    else {
        delete $resource_by{$id};
        _reply('200 OK', 'text/plain', "Resource #$id deleted");
    }
}



#
# Despatxa segons URL i operació contra aquest
# controlador. La URL és un pattern amb blocs nominals
# que són automàticament passats a la funció.
#
# Nota: hauria de funcionar amb "named buffers" però només
# s'implementen a partir de perl 5.10. Quina misèria, no?
# A Python fa temps que funcionen...
#
my %crud_for = (
    '/resources' => {
         GET    => \&_list_resources,
    },
    '/resource/(\d+)' => {
	 POST   => \&_create_resource,
         GET    => \&_retrieve_resource,
         PUT    => \&_update_resource,
         DELETE => \&_delete_resource,
    },
    '/resource/(\d+)/bookings' => {
         GET    => \&_reply_default,
         POST   => \&_reply_default,
    },
    '/booking/(\d+)' => {
         GET    => \&_reply_default,
         PUT    => \&_reply_default,
         DELETE => \&_reply_default,
    },
    'default_action' => {
         POST   => \&_reply_default,
         GET    => \&_reply_default,
         PUT    => \&_reply_default,
         DELETE => \&_reply_default,
    },
);


#
# Aquest és el handler que invoca el ServerHTTP per a cada
# request que ha de resoldre. El handler ha de trencar la URL del
# request i determinar qui ha de donar el servei.
#
sub handle_request {
    my $self = shift;

    # Obté les dades del request via CGI
    $cgi  = shift;
    my $path_info = $cgi->path_info();
    my $method    = $cgi->request_method();

    # Busca el primer pattern del diccionari que s'acara.
    my $url_key = 'default_action';
    foreach my $url_pattern (keys(%crud_for)) {
	my $pattern = '^' . $url_pattern . '/?$'; # allow URLs ending in '/'
	if ($path_info =~ m{$pattern}) {
	    $url_key = $url_pattern;
	    last;
	}
    }

    # Despatxa segons recurs i mètode invocat
    if (exists $crud_for{$url_key}->{$method}) {
	$crud_for{$url_key}->{$method}->($1);
    } else {
	# Requested http method not available
	_fail(405);
    }
}


1;
