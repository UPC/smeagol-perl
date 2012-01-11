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
    
    my $result = $r->{$test->{op}}->( 
            id => $test->{id}, 
            args => $test->{args}, 
            new_ids => $test->{new_ids}, 
            status => $test->{new_ids} 
        );
}
