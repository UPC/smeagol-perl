package DataStore;
use Data::Dumper;

#use Storable qw(nstore retrieve);

my $db_path = "/tmp/";

sub load {
    my $self = shift;
    my ($id) = @_;
    my $data;
    if ( -e $db_path . $id . '.db' ) {

        #$data = retrieve($id.'.db') or die;
        $data = require( $db_path . $id . '.db' );
    }
    return $data;
}

sub save {
    my $self = shift;
    my ( $id, $data ) = @_;

    #nstore(\$data, $id.'.db') or die;
    open my $out, ">", $db_path . $id . '.db' or die;
    print $out Dumper($data);
    close $out;

}

sub exists {
    my $self = shift;
    my ($id) = @_;
    if ( -e $db_path . $id . '.db' ) {
		return 1;
    }
	return 0;
}

sub list_id {
	my $self = shift;
	my @list;
	my @files = <$db_path.*>;
	foreach (@files) {
		push @list, $_;
	}
	return @list;
}

sub init_path {
	my $self = shift;
	$db_path = @_;
}

1;
