package DataStore;
use Storable;


sub new {
    my $class = shift;

    my $obj;

    bless $obj, $class;
}

sub load {
    my $self = shift;
    my $data;
    if(-e 'data.db'){
    	$data = retrieve('data.db') or die;
    }
}

sub store {
    my $self = shift;
    my ($data) = @_;
    nstore($data, 'data.db') or die;
}

1;
