package HTTP::Request::Common::Bug65843;

# do not import PUT
my @methods;
BEGIN { @methods = qw( GET POST DELETE ) }
use HTTP::Request::Common @methods;

# do export fixed PUT
use Exporter 'import';
push @methods, 'PUT';
our @EXPORT_OK = @methods;

push our @ISA, 'HTTP::Request::Common';

sub PUT {
    my $r = POST(@_);
    $r->method('PUT');
    return $r;
}

1;
