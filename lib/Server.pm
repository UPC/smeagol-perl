package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

use Resource;
use YAML::Tiny;

my %resource_by;
my $last_id;
my $cgi;

sub _reply {
    my ($status, $type, @output) = @_;

    $type = 'text/plain'
        unless defined $type and $type ne '';

    print "HTTP/1.0 $status\n", $cgi->header('-type' => $type), @output, "\n";
}

sub _reply_default {
    _reply('400 Bad Request', 'text/plain', 'Bad Request');
}

sub _list_resources {
    my $yaml = YAML::Tiny->new();
    $yaml->[0] = \%resource_by;

    _reply('200 OK', 'text/yaml', $yaml->write_string());
}

sub _create_resource {
    my $params = shift;

    my $id = $params->{'id'};
    $id = ++$last_id
        unless defined $id;

    my $desc = $params->{'desc'};

    if (exists $resource_by{$id}) {
        _reply('403 Forbidden', 'text/plain', "Resource #$id already exists!");
    }
    elsif (!defined $desc) {
        _reply('400 Bad Request', 'text/plain', 'Missing description!');
    }
    else {
        $resource_by{$id} = Resource->new($id, $desc);
        _reply('201 Created', 'text/plain', "Resource #$id created");
    }
}

sub _retrieve_resource {
    _reply_default();
}

sub _update_resource {
    _reply_default();
}

sub _delete_resource {
    _reply_default();
}


my %crud_for = (
    POST   => \&_create_resource,
    GET    => \&_retrieve_resource,
    PUT    => \&_update_resource,
    DELETE => \&_delete_resource,
);


sub print_banner {}


sub new {
    my $class = shift;

    my $server = $class->SUPER::new(@_);

    bless $server, $class;
}

sub handle_request {
    my $self = shift;

    $cgi  = shift;
    my $path_info = $cgi->path_info();
    my $method    = $cgi->request_method();

    my (undef, $main, $id, @args) = split m{/+}, $path_info;

    if ($main eq 'resources' and $method eq 'GET') {
        _list_resources();
    }
    elsif ($main eq 'resource' and exists $crud_for{$method}) {
        $crud_for{$method}->($cgi->Vars);
    }
    else {
        # unknown request
        _reply_default();
    }
}

1;
