package DataStore;
use Data::Dumper;
#use Storable qw(nstore retrieve);


sub load {
    my $self = shift;
    my ($id) = @_;
    my $data = 0;
    if(-e "/tmp/".$id.'.db'){
        #$data = retrieve($id.'.db') or die;
        $data = require ("/tmp/".$id.'.db');
    }
    return $data;
}

sub save {
    my $self = shift;
    my ($id,$data) = @_;
    #nstore(\$data, $id.'.db') or die;
    open my $out, ">",  "/tmp/".$id.'.db' or die;
    print $out Dumper($data);
    close $out;

}

1;
