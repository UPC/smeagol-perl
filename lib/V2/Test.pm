package V2::Test;

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

    my $json;
    subtest "GET $uri request" => sub {
        my $res  = request HTTP_GET($uri);

        ok( $res->is_success, "GET $uri successful" );

        $json = decode_json( $res->decoded_content );

        ok( ref($json) eq 'ARRAY' || ref($json) eq 'HASH', "GET $uri content is json" );

        done_testing();
    };

    return @_ ? $json : _list_of_id(@$json);
}

sub POST {
    my $self = shift;
    my @args = @_;

    croak "args needed" unless @args;

    my $uri = $self->uri;

    my @new_ids;
    subtest "POST $uri request" => sub {
        my @before = $self->GET();
        my $res    = request HTTP_POST( $uri, @args );

        ok( $res->is_success, "POST $uri successful" );

        my @after = $self->GET();
        @new_ids  = List::Compare->new( \@before, \@after )->get_complement;

        ok( @new_ids == 1, "POST $uri created @new_ids" );

        done_testing();
    };

    return $new_ids[0];
}

sub PUT {
    my $self = shift;
    my $id   = shift // croak "id needed";
    my $uri  = $self->uri . "/$id";
    my @args = @_;

    croak "args needed" unless @args;

    subtest "PUT $uri request" => sub {
        my $res = request HTTP_PUT( $uri, @args );

        ok( $res->is_success, "PUT $uri successful" );
        
        done_testing();
    };

    return;
}

sub DELETE {
    my $self = shift;
    my $id   = shift // croak "id needed";

    my $uri  = $self->uri;
    $uri    .= "/$id";

    subtest "DELETE $uri request" => sub {
        my $res  = request HTTP_DELETE($uri);

        ok( $res->is_success, "DELETE $uri successful" );
        
        done_testing();
    };

    return;
}

1;
