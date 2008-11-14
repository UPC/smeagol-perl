package DataStore;
use Storable qw(nstore retrieve);


sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
}

sub load {
    my $self = shift;
    $self = retrieve('data.db') or die;
}

sub store {
    my $self = shift;
    nstore($self, 'data.db') or die;
}
