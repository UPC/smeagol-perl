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

# Builds the uri for a test, given a hash with the following key-values:
#  {
#    uri     => (required) The URI prefix ("/resource", "/event", etc).
#    id      => 
#    postfix => (optional) an array of url segments to be appended to the prefix.
#               The segments can be strings or code references.
#  }
#
sub build_uri {
    my (%params) = @_;

    my $uri = $params{'uri'};

    if ( exists $params{'postfix'} && defined $params{'postfix'} ) {
        $uri .= evaluate_and_concat( $params{'postfix'} );
    }

    return $uri;
}

# Builds a string, given an array reference composed by strings or function references.
#
# For instance, evaluate_and_concat([ 'tag?resource=', \&get_generated_id ])
# returns "/tag?resource=ID"
#
sub evaluate_and_concat {
    my ($params) = @_;
    my $url = '';
    for my $elem ( @{$params} ) {
        $url .= '/' . ( ref $elem eq 'CODE' ? $elem->() : $elem );
    }
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

    my $uri
        = build_uri( uri => $test->{'uri'}, postfix => $test->{'postfix'} );

    diag( $test->{'op'} . ' ' . $uri );

    my $r = V2::Test->new( uri => $uri );

    # V2::Test doesn't expect a 'uri' key in tests
    delete $args{'uri'} if exists $args{'uri'};

    my $op = $test->{'op'};

    my $got = $r->$op(%args);

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
    $args{'args'}    = $test->{'input'}   if defined $test->{'input'};
    $args{'new_ids'} = $test->{'new_ids'} if defined $test->{'new_ids'};
    $args{'status'}  = $test->{'status'}  if defined $test->{'status'};

    # FIXME: is it possible to simplify the following code?
    if ( exists $test->{'output'} ) {
        $args{'result'} = $test->{'output'};
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

