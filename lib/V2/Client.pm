package Smeagol::Client;

use strict;
use warnings;

use DateTime;
use LWP::UserAgent;
use Carp;
use Data::Dumper;
#use XML::LibXML;
#use XML::Simple;

use Moose;

use Smeagol::Client::Resource;

has 'url' => ( 
		is => 'rw',
		required => 1,
		default => sub {
		        	my $self = shift;
					my %args = @_;
        			return $args{url};
    		}
	     );
has 'ua'  => (
		isa => 'LWP::UserAgent',
		is => 'rw',
		required => 1,
		default => sub {
		        	my $self = shift;
					my $ua = LWP::UserAgent->new();
					$ua->agent("SmeagolClient/0.1 ");
        			return $ua;
    		}
	     );
has 'resource' => ( is =>'rw', isa => 'Smeagol::Client::Resource');

1;
