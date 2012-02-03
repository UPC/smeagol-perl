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

my @tests = @{ require 'doc/api/Resource_v2.pl' };

for my $t (@tests) {
    test_smeagol_resource($t);
}

sub get_generated_id {
    return $GENERATED_RESOURCE_ID;
}

done_testing();

sub test_smeagol_resource {
    my ($test) = @_;

    my $r = V2::Test->new( uri => '/resource' );

    my $method = $test->{method};
    my %args   = prepare_args($test);
    my $expected = delete $args{result};

    my $got = $r->$method(%args);

    if ($method eq 'GET') {
    
    } else if ($method eq 'POST') {
    
    }

    $GENERATED_RESOURCE_ID = $got if exists $args{new_ids} && $args{new_ids} != 0;

    is_deeply( $got, (ref $got eq 'ARRAY') ? $test->{result} : $test->{result}[0], $test->{title} . ": result does match" );
}

sub prepare_args {
    my ($test) = @_;
    my %args;

    if (exists $test->{id}) {
        $args{id} = (ref $test->{id} eq 'CODE') ? $test->{id}->() : $test->{id};
    }
    $args{args}    = $test->{args}    if defined $test->{args};
    $args{new_ids} = $test->{new_ids} if defined $test->{new_ids};
    $args{status}  = $test->{status}  if defined $test->{status};
    if (exists $test->{result}) {
        $args{result} = $test->{result};
        if (ref $args{result} eq 'ARRAY') {
            foreach my $val (@{ $args{result} }) {
                if (exists $val->{id}) {
                    if (ref $val->{id} eq 'CODE') {
                        $val->{id} = $val->{id}->();
                    }
                }
            }
        }
    }

    return %args;
}

