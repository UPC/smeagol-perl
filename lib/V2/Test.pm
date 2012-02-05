package V2::Test;

use Moose;
use MooseX::Params::Validate qw( validated_hash );
use Catalyst::Test 'V2::Server';

use Test::More;

use Carp qw( croak       );
use JSON qw( decode_json );

use List::Compare         ();
use HTTP::Request::Common ();

BEGIN {
    my @op_list = qw( GET POST DELETE );

    for my $op (@op_list) {
        no strict 'refs';

        *{ "HTTP_$op" } = \&{ "HTTP::Request::Common::$op" };
    }
}

# FIXME (CPAN #65843)
sub HTTP_PUT {
    my $req = HTTP_POST(@_);
    $req->method('PUT');

    return $req;
}

has 'uri' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _list_of_id {
    return map { $_->{'id'} } @_;
}

sub _default_status {
    return shift->is_success;
}

sub GET {
    my ( $self, %params ) = validated_hash(
	\@_,
        id     => { isa => 'Str', optional => 1 },
        status => { isa => 'CodeRef', default => \&_default_status },
    );

    my $uri  = $self->uri;
    $uri    .= "/$params{'id'}" if exists $params{'id'};

    my $json;
    subtest "GET $uri request" => sub {
        my $res  = request HTTP_GET($uri);

        ok( $params{'status'}->($res), "GET $uri successful" );

        $json = decode_json( $res->content );

        ok( ref($json) eq 'ARRAY' || ref($json) eq 'HASH', "GET $uri content is json" );

        done_testing();
    };

    return @_ ? $json : _list_of_id(@$json);
}

sub POST {
    my ( $self, %params ) = validated_hash(
	\@_,
        status  => { isa => 'CodeRef', default => \&_default_status },
        args    => { isa => 'ArrayRef | HashRef' },
	    new_ids => { isa => 'Num', default => 1 },
    );

    my $uri = $self->uri;

    my @new_ids;
    subtest "POST $uri request" => sub {
        my @before      = $self->GET();
        my ($res, $ctx) = ctx_request HTTP_POST( $uri, $params{'args'} );

        ok( $params{'status'}->($res), "POST $uri successful" );

        my @after = $self->GET();
        @new_ids  = List::Compare->new( \@before, \@after )->get_complement;

        ok( @new_ids == $params{'new_ids'}, "POST $uri created @new_ids" );

        SKIP: {
            skip "Location header not expected", 2
                if $params{'new_ids'} == 0;

            # uri received by server
            my $server_uri = $ctx->req->uri;

            # make sure that uri ends with slash
            $server_uri .= '/' unless $server_uri =~ m{/$};

            my $location = $res->header('Location');

            ok( defined $location, "Location header present" );

            skip "Location header is undefined", 1
                unless defined $location;

            like(
                $location,
                qr{^\Q$server_uri\E/*$new_ids[0]$},
                "Location header value <$location>",
            );
        };

        done_testing();
    };

    return @new_ids[ 0 .. $params{'new_ids'} - 1 ];
}

sub PUT {
    my ( $self, %params ) = validated_hash(
	\@_,
        id      => { isa => 'Str' },
        status  => { isa => 'CodeRef', default => \&_default_status },
        args    => { isa => 'ArrayRef | HashRef' },
    );
    my $uri  = $self->uri . "/$params{'id'}";

    subtest "PUT $uri request" => sub {
        my $res = request HTTP_PUT( $uri, $params{'args'} );

        ok( $params{'status'}->($res), "PUT $uri successful" );
        
        done_testing();
    };

    return;
}

sub DELETE {
    my ( $self, %params ) = validated_hash(
	\@_,
        id      => { isa => 'Str' },
        status  => { isa => 'CodeRef', default => \&_default_status },
    );

    my $uri  = $self->uri;
    $uri    .= "/$params{'id'}";

    subtest "DELETE $uri request" => sub {
        my $res  = request HTTP_DELETE($uri);

        ok( $params{'status'}->($res), "DELETE $uri successful" );
        
        done_testing();
    };

    return;
}

1;
