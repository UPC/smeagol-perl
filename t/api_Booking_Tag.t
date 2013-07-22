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
use DateTime;

my @tests = @{ require 'doc/api/Booking_Tag.pl' };

# global variable to store server-generated ids
my %OBJECT_IDS = (
    resource => undef,
    event    => undef,
    booking  => undef,
);

# returns last generated id for resource type
# arguments:
#   $type : the resource type ('resource', 'event', or 'booking')
sub get_generated_id {
    my $type = shift;

    return $OBJECT_IDS{$type};
}

# sets last generated id for resource type
# arguments:
#     $type : the resource type ('resource', 'event' or 'booking')
#     $id   : the last generated id
sub set_generated_id {
    my ( $type, $id ) = @_;

    $OBJECT_IDS{$type} = $id;
}

# Builds the uri for a test, given a hash with the following key-values:
#  {
#    uri     => (required) The URI prefix ("/resource", "/event", etc).
#    id      => (optional) the ID of the resource, when needed
#  }
#
sub build_uri {
    my (%params) = @_;

    my $uri
        = ref $params{'uri'} eq 'ARRAY'
        ? evaluate_and_concat( $params{'uri'} )
        : $params{'uri'};

    $uri .= '/' . $params{'id'} if defined $params{'id'};
    return $uri;
}

# Builds a string as a concatenation of the elements contained in a given
# array reference containing strings or function references.
#
# For instance, evaluate_and_concat([ '/tag?resource=', \&function_name ])
# returns "/tag?resource=FOO"  (where FOO is the result of function_name())
#
sub evaluate_and_concat {
    my ($params) = @_;
    my $result = '';
    for my $elem ( @{$params} ) {
        $result .= ref $elem eq 'CODE' ? $elem->() : $elem;
    }
    return $result;
}

# main loop
for my $t (@tests) {
    run_test($t);
}

done_testing();

sub run_test {
    my ($test) = @_;

    my %args = prepare_args($test);

    my $uri = build_uri( uri => $test->{'uri'}, id => $test->{'id'} );

    my $r = V2::Test->new( uri => $uri );

    # V2::Test doesn't expect a 'uri' key in tests
    delete $args{'uri'} if exists $args{'uri'};

    my $op = $test->{'op'};

    my $got = $r->$op(%args);

    if ( exists $args{'new_ids'} && $args{'new_ids'} != 0 ) {
        if ( $uri =~ m{/(\w+)$} ) {
            set_generated_id( $1, $got );
        }
    }
}

# Parse test hash and prepare arguments for the test call, performing
# deferred evaluation in fields which are function references.
sub prepare_args {
    my ($test) = @_;
    my %args;

    $args{'id'} = V2::Test->deferred_eval( $test->{'id'} )
        if exists $test->{'id'};
    $args{'args'} = V2::Test->deferred_eval( $test->{'input'} )
        if exists $test->{'input'};
    $args{'new_ids'} = $test->{'new_ids'} if exists $test->{'new_ids'};
    $args{'status'}  = $test->{'status'}  if exists $test->{'status'};
    $args{'result'} = V2::Test->deferred_eval( $test->{'output'} )
        if exists $test->{'output'};

    return %args;
}

