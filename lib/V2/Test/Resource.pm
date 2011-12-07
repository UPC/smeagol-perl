package V2::Test::Resource;

use Moose;
use Catalyst::Test 'V2::Server';

use Test::More;
use Carp          qw( croak       );
use JSON          qw( decode_json );
use List::Compare qw(             );

use lib 't/lib';
use HTTP::Request::Common::Bug65843 ();

{
    my @op_list = qw( GET POST PUT DELETE );

    for my $op (@op_list) {
        no strict 'refs';

        *{ "HTTP_$op" } = \&{ "HTTP::Request::Common::Bug65843::$op" };
    }
}

has 'uri' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _list_of_id {
    return map { $_->{'id'} } @_;
}

sub GET {
    my $self = shift;
    my ($id) = @_;

    my $uri  = $self->uri;
    $uri    .= "/$id" if @_;
    my $res  = request HTTP_GET($uri);

    croak "request unsuccessful" unless $res->is_success;

    my $json = decode_json( $res->decoded_content );

    return @_ ? $json : _list_of_id(@$json);
}

sub POST {
    my $self = shift;

    croak "args needed" unless @_;

    my @before = $self->GET();
    my $res    = request HTTP_POST( $self->uri, @_ );

    croak "request unsuccessful" unless $res->is_success;

    my @after   = $self->GET();
    my @new_ids = List::Compare->new( \@before, \@after )->get_complement;

    croak "too many new resources" unless @new_ids == 1;

    return $new_ids[0];
}

sub PUT {
    my $self = shift;
    my $id   = shift // croak "id needed";
    my $uri  = $self->uri . "/$id";

    croak "args needed" unless @_;

    my $res = request HTTP_PUT( $uri, @_ );

    croak "request unsuccessful" unless $res->is_success;

    return;
}

sub DELETE {
    my $self = shift;
    my $id   = shift // croak "id needed";

    my $uri  = $self->uri;
    $uri    .= "/$id";

    my $res  = request HTTP_DELETE($uri);

    croak "request unsuccessful" unless $res->is_success;

    return;
}

1;
