package DataStore;
use Data::Dumper;

#use Storable qw(nstore retrieve);

my $db_path = "/tmp/";

sub load {
    my $self = shift;
    my ($id) = @_;
    my $data;
	if(defined $id && -e $db_path . $id . '.db' ) {

        #$data = retrieve($id.'.db') or die;
        $data = require( $db_path . $id . '.db' );
    }
    return $data;
}

sub save {
    my $self = shift;
    my ( $id, $data ) = @_;
	if(defined $id && defined $data){
    	#nstore(\$data, $id.'.db') or die;
    	open my $out, ">", $db_path . $id . '.db' or die;
    	print $out Dumper($data);
    	close $out;
	}

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
    my @files = <$db_path.*.'.db'>;
    foreach (@files) {
        my ($id, $dummy) = split(/\./, $_); # remove ".db" from filename
        push @list, $id;
    }
    return @list;
}

sub init_path {
    my $self = shift;
    my $path = shift;

    if ( !-e $path ) {
        mkdir $path or die "Could not create DataStore path $path\n";
    }
    $db_path = $path;
}

sub next_id{
	my $self = shift;
	my ($kind) = @_;
	my $data = 1;
	if(defined $kind){
		if ( -e $db_path.'/next_'.$kind ) {
        	$data = require( $db_path.'/next_'.$kind );
			$data++;
    	}
		open my $out, ">", $db_path.'/next_'.$kind or die;
		print $out Dumper($data);
		close $out;
		return $data;
	}else{
		return undef;
	}
}

1;
