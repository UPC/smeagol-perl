package DataStore;
use Storable qw(nstore retrieve);
use Data::Dumper;

my @data;

sub add {
    my $self = shift;
    push @data, @_ ;
}

sub load {
    if(-e 'data.db'){
    	@data = retrieve('data.db') or die;
    }
    return @data;
}

sub save {
    nstore(\@data, 'data.db') or die;
}

1;
