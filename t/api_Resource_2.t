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

# global variable to store server-generated IDs
my $GENERATED_RESOURCE_ID;

my @tests = @{ require 'doc/api/Resource.pl' };

for my $t (@tests) {
    test_smeagol_resource($t);
}

done_testing();

sub test_smeagol_resource {
    my ($test) = @_;

    my $r = V2::Test->new( uri => '/resource' );
    
    my $method = $test->{method};
    my %args = prepare_args($test);
    my $result = $r->$method( %args );
    
    is_deeply($result, $test->{result}, $test->{title} . ": result does match") if exists $test->{result};
}


sub prepare_args {
    my ($test) = @_;
    my %args;
    
    $args{id} = $test->{id} if defined $test->{id};
    $args{args} = $test->{args} if defined $test->{args};
    $args{new_ids} = $test->{new_ids} if defined $test->{new_ids};
    $args{status} = $test->{status} if defined $test->{status};
    
    return %args;
}

