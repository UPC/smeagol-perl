package Server;

use strict;
use warnings;

use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);

use Resource;
use YAML::Tiny;

my %resource_by;
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
    my ($id, @args) = @_;

    $id = $cgi->param('id')
        unless defined $id;
    my $desc = $cgi->param('desc');
    my $gra  = $cgi->param('gra');

    if (defined $id && exists $resource_by{$id}) {
        _reply('403 Forbidden', 'text/plain', "Resource #$id already exists!");
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
        _reply('400 Bad Request', 'text/plain', 'Missing description!');
    }
}

sub _retrieve_resource {
    my ($id, @args) = @_;

    if (!defined $id || !exists $resource_by{$id}) {
        _reply('404 Not Found', 'text/plain',
               "Resource does not exist!");
    }
    else {
        _reply('200 OK', 'text/xml', $resource_by{$id}->to_xml());
    }
}

sub _update_resource {
    _reply_default();
}

sub _delete_resource {
    my ($id, @args) = @_;

    if (!defined $id || !exists $resource_by{$id}) {
        _reply('404 Not Found', 'text/plain',
               "Resource does not exist!");
    }
    else {
        delete $resource_by{$id};
        _reply('200 OK', 'text/plain', "Resource #$id deleted");
    }
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
        $crud_for{$method}->($id, @args);
    }
    else {
        # unknown request
        _reply_default();
    }
}

1;
