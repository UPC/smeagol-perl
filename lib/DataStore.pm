package DataStore;
use Storable;
use Data::Dumper;


sub new {
    my $class = shift;
    return bless {}, $class;
}

sub load {
    my $self = shift;
    my $data;
    if(-e 'data.db'){
    	$data = retrieve('data.db') or die;
    }
    return $data;
}

sub save {
    my $self = shift;
    nstore($self, 'data.db') or die;
}

1;
