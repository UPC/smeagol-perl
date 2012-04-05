package V2::Test;

=head1 NAME

V2::Test - V2::Server tests made easy

=head1 SYNOPSIS

Test server API thoroughly and make easy to test its funcionality:

    my $tag = V2::Test->new( uri => '/tag' );
    
    my $new_tag_id = $tag->POST( args => {
        id => 'tag-name',
        description => 'tag-description',
    } );
    
    my $new_tag = $tag->GET( id => $new_tag_id );
    print $new_tag->{'tag-name'};
    print $new_tag->{'tag-description'};
    
    my @tags = $tag->GET();
    print @tags;
    
    my $struct = V2::Test->deferred_eval(
                    { id   => sub { very_complex_calculation() }, 
                      desc => 'hello!',
                      x    => [ 'a', \&my_sub ],
                    }
                 );

=head1 DESCRIPTION

The purpose of this module is that unit tests for server can
forget about API and focus on checking the expected results.
This module will make sure that the requests to server are
sent properly and results received match the public API.

Thus, unit tests don't need to check whether the format of
results is correct according to the public API. They only
have to check whether they have the expected values after
server performed the requested operation.

=cut

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
    return !shift->is_error;
}

=head1 METHODS

=head2 GET

GET method is a read-only method and thus idempotent. It returns
a list of objects unless B<id> is provided, in which case it will
return the object matching that.

=head3 Parameters

=over 4

=item * id (Str)

String ID to locate an object.

=item * status (CodeRef)

Code reference that gets a L<HTTP::Status> object and defaults to success.

=item * result (ArrayRef | HashRef)

Array reference (when B<id> is not provided) or hash reference
(for the provided B<id>) describing the expected result.

=back

=cut

sub GET {
    my ( $self, %params ) = validated_hash(
	\@_,
        id     => { isa => 'Str', optional => 1 },
        status => { isa => 'CodeRef', default => \&_default_status },
        result => { isa => 'ArrayRef | HashRef', optional => 1 },
    );

    my $uri  = $self->uri;
    $uri    .= "/$params{'id'}" if exists $params{'id'};

    my $json;
    my $get_id_success;
    subtest "GET $uri request" => sub {
        my $res  = request HTTP_GET($uri);

        #$DB::single=($uri eq '/resource/1/tag');
        ok( $params{'status'}->($res), "GET $uri status" );

        $json           = decode_json( $res->content );
        $get_id_success = exists $params{'id'} && $res->is_success;

        ok(
            $get_id_success ?
            ref($json) eq 'HASH' :
            ref($json) eq 'ARRAY',
            "GET $uri content is API compliant",
        );

        SKIP: {
            skip "Expected result not provided", 1
                unless exists $params{'result'};

            is_deeply( $json, $params{'result'}, "Same result as expected" );
        };

        done_testing();
    };

    return $get_id_success ? $json : _list_of_id(@$json);
}

=head2 POST

=head3 Parameters

=over 4

=item * args (ArrayRef | HashRef)

Array or hash reference of name/value pairs to pass into
L<HTTP::Request> object as the form input.

=item * new_ids (Num)

Number of new objects created: 0 if error was being tested and
1 by default. Higher values are supported but unexpected.

=item * status (CodeRef)

Code reference that gets a L<HTTP::Status> object and defaults to success.

=item * result (ArrayRef)

Array reference describing the expected result.

=back

=cut

sub POST {
    my ( $self, %params ) = validated_hash(
	\@_,
        status  => { isa => 'CodeRef', default => \&_default_status },
        args    => { isa => 'ArrayRef | HashRef' },
        new_ids => { isa => 'Num', default => 1 },
        result  => { isa => 'ArrayRef', default => [] },
    );

    my $uri = $self->uri;

    my @new_ids;
    subtest "POST $uri request" => sub {
        my @before      = $self->GET();
        my ($res, $ctx) = ctx_request HTTP_POST( $uri, $params{'args'} );

        my $status = $params{'status'}->($res);
        ok( $status, "POST $uri status" );

        my $json = decode_json( $res->content );
        ok( ref($json) eq 'ARRAY', "POST $uri content is API compliant" );
        is_deeply( $json, $params{'result'}, "Same result as expected" );

        SKIP: {
            skip "Unsuccessful request", 3
                unless $res->is_success;

            my @after = $self->GET();
            @new_ids  = List::Compare->new( \@before, \@after )->get_complement;

            ok( @new_ids == $params{'new_ids'}, "POST $uri created @new_ids" );

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

=head2 PUT

=head3 Parameters

=over 4

=item * id (Str)

String ID to locate an object.

=item * args (ArrayRef | HashRef)

Array or hash reference of name/value pairs to pass into
L<HTTP::Request> object as the form input.

=item * status

Code reference that gets a L<HTTP::Status> object and defaults to success.

=item * result

Array reference describing the expected result.

=back

=cut

sub PUT {
    my ( $self, %params ) = validated_hash(
	\@_,
        id      => { isa => 'Str' },
        status  => { isa => 'CodeRef', default => \&_default_status },
        args    => { isa => 'ArrayRef | HashRef' },
        result  => { isa => 'ArrayRef', default => [] },
    );
    my $uri  = $self->uri . "/$params{'id'}";

    subtest "PUT $uri request" => sub {
        my $res = request HTTP_PUT( $uri, $params{'args'} );

        ok( $params{'status'}->($res), "PUT $uri status" );
        
        my $json = decode_json( $res->content );
        ok( ref($json) eq 'ARRAY', "PUT $uri content is API compliant" );
        is_deeply( $json, $params{'result'}, "Same result as expected" );

        done_testing();
    };

    return;
}

=head2 DELETE

=head3 Parameters

=over 4

=item * id (Str)

=item * status (CodeRef)

Code reference that gets a L<HTTP::Status> object and defaults to success.

=item * result (ArrayRef)

Array reference describing the expected result.

=back

=cut

sub DELETE {
    my ( $self, %params ) = validated_hash(
	\@_,
        id      => { isa => 'Str' },
        status  => { isa => 'CodeRef', default => \&_default_status },
        result  => { isa => 'ArrayRef', default => [] },
    );

    my $uri  = $self->uri;
    $uri    .= "/$params{'id'}";

    subtest "DELETE $uri request" => sub {
        my $res  = request HTTP_DELETE($uri);

        ok( $params{'status'}->($res), "DELETE $uri status" );
        
        my $json = decode_json( $res->content );
        ok( ref($json) eq 'ARRAY', "DELETE $uri content is API compliant" );
        is_deeply( $json, $params{'result'}, "Same result as expected" );

        done_testing();
    };

    return;
}


=head2 deferred_eval

Deeply evaluates any kind of data structure. Useful for evaluating references
in test 'input' or 'output' parameters.

=head3 Parameters

=over 4

=item * CodeRef | ArrayRef | HashRef | Scalar

=back

=head3 Result

An equivalent structure reference, containing que deferred evaluation of the
structure.

=cut

sub deferred_eval {
    my $class = shift;
    $class eq __PACKAGE__ or croak 'deferred_eval() is a class method';
    
    my ($arg) = @_;
    
    if (ref $arg eq 'HASH') {
        my %result;
        
        @result{ keys %{$arg} } = map { (ref $_ eq 'CODE') ? $_->() : __PACKAGE__->deferred_eval($_) } values %{$arg};
        return \%result;
    }
    
    if (ref $arg eq 'ARRAY') {
        my @result;
    
        @result = map { (ref $_ eq 'CODE') ? $_->() : __PACKAGE__->deferred_eval($_) } @{$arg} ;    
        return \@result;
    }
    
    if (ref $arg eq 'CODE') {
        return $arg->();
    }
    
    return $arg;
}


1;
