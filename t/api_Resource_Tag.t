#!perl

use strict;
use warnings;

BEGIN {
    require 't/TestingDB.pl';
}

use V2::Test;
use Test::More;
use utf8::all;
use HTTP::Status qw(:constants :is status_message);
use Data::Dumper;

my @tests = @{ require 'doc/api/Resource_Tag.pl' };

# global variable to store server-generated IDs
my $OBJECT_ID;

# get generated ID (for deferred evaluation)
sub get_generated_id {
    return $OBJECT_ID;
}


# Builds the url for a test, given a hash with the following values:
#  {
#    type => (required) "resource", "event" or "booking"
#    id   => (required) the id of the resource/event/booking (required),
#              or reference to a function which returns the id
#    tag  => (optional) the tag name
#  }
# For instance, get_generated_url('resource',23,'aula') returns "/resource/23/tag/aula"
#
sub test_url {
    my ($params) = @_;
    my $url = '/' . $params->{'type'};
    if ( defined $params->{'id'} ) {
        $url .=
            '/' . ( ref $params->{'id'} eq 'CODE' 
            ? $params->{'id'}->()
            : $params->{'id'});
        $url .= '/tag';
    }
    $url .= ('/' . $params->{'tag'}) if ( defined $params->{'tag'} );
    return $url;
}

# main loop
for my $t (@tests) {
    run_test($t);
}

done_testing();

sub run_test {
    my ($test) = @_;

    my %args = prepare_args($test);

    my $r = V2::Test->new( uri => test_url( $test->{'url'} ) );

    # V2::Test doesn't expect a 'url' key in tests
    delete $args{'url'} if exists $args{'url'};

    my $method = $test->{'method'};

    my $got = $r->$method(%args);

    $OBJECT_ID = $got if ( exists $args{'new_ids'} && $args{'new_ids'} != 0 );
}

# Parse test hash and prepare arguments for test call, performing
# deferred evaluation in fields with function references.
# when needed.
sub prepare_args {
    my ($test) = @_;
    my %args;

    if ( exists $test->{'id'} ) {
        $args{'id'}
            = ( ref $test->{'id'} eq 'CODE' )
            ? $test->{'id'}->()
            : $test->{'id'};
    }
    $args{'args'}    = $test->{'args'}    if defined $test->{'args'};
    $args{'new_ids'} = $test->{'new_ids'} if defined $test->{'new_ids'};
    $args{'status'}  = $test->{'status'}  if defined $test->{'status'};

    # FIXME: is it possible to simplify the following code?
    if ( exists $test->{'result'} ) {
        $args{'result'} = $test->{'result'};
        if ( ref $args{'result'} eq 'ARRAY' ) {
            foreach my $val ( @{ $args{'result'} } ) {
                if ( exists $val->{'id'} && ref $val->{'id'} eq 'CODE' ) {
                    $val->{'id'} = $val->{'id'}->();
                }
            }
        }
        elsif ( exists $args{'result'}{'id'}
            && ref $args{'result'}{'id'} eq 'CODE' )
        {
            $args{'result'}{'id'} = $args{'result'}{'id'}->();
        }
    }

    return %args;
}

