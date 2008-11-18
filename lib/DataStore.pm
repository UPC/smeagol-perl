package DataStore;
use Storable;
use Data::Dumper;

my @data;

sub add {
    my $self = shift;
    push @data, @_ ;
}

sub load {
    my $self = shift;
    if(-e 'data.db'){
    	@data = retrieve('data.db') or die;
    }
    return @data;
}

sub save {
    my $self = shift;
    nstore(@data, 'data.db') or die;
}

1;
