package V2::Client;

use Moose;    # automatically turns on strict and warnings

use LWP::UserAgent;

my $USER_AGENT_PREFIX = 'SmeagolClient/2.0';

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
    isa      => 'LWP::UserAgent',
    is       => 'ro',
    required => 1,
    default  => sub {
        my $self = shift;
        my $ua   = LWP::UserAgent->new();
        $ua->agent( $USER_AGENT_PREFIX . ' ' . $ua->_agent );
        return $ua;
    }
);

1;

