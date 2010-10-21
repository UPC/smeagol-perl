package V2::Client;

use Moose;    # automatically turns on strict and warnings
use LWP::UserAgent;

our $VERSION           = 2.0;
our $USER_AGENT_PREFIX = "SmeagolClient/$VERSION";

has 'url' => (
    is       => 'ro',
    required => 1,
    default  => sub {
        my $self = shift;
        my %args = @_;

        my $url = $args{url};
        $url = chop $url if ( $url =~ /\/$/ );

        return $url;
    }
);

has 'ua' => (
    isa => 'LWP::UserAgent',
    is  => 'ro',
    lazy    => 1,      # do not create this slot until absolutely necessary
    default => sub {
        my $self = shift;
        my $ua   = LWP::UserAgent->new();
        $ua->default_header( 'Accept' => 'application/json' );
        $ua->agent( $USER_AGENT_PREFIX . ' ' . $ua->_agent );
        return $ua;
    }
);

# return full url with REST path segment included (e.g. http://server:port/tag).
# this method MUST BE OVERRIDEN in subclasses
sub _fullPath {
    my $self = shift;
    return $self->url;
}

1;

__END__

=head1 NAME

Smeagol::Client - Base class for Smeagol::Client::* instances

=head1 SYNOPSIS

This class is not intended to be used directly. Use its subclasses instead.
  
=cut
