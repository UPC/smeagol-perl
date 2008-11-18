package DataStore;
use Storable;
use Data::Dumper;


sub new {
    my $class = shift;
    return bless [], $class;
}

sub add {
    my $self = shift;
    my $data = @_;
    push @$self, $data;
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
    my $dades = @_;
    nstore($dades, 'data.db') or die;
}

1;
