package DataStore;
use Data::Dumper;


my $_PATH = "/tmp/smeagol_datastore/";

# init($path): sets DataStore storage path. 
#       $path argument indicates the directory
#       where persistent files will be stored.
#       $path directory will be created, if needed.
sub init {
    my $path  = shift;

    defined($path) or die "DataStore->init() needs an argument!\n";

    # Create the path, if needed
    if ( -d $path ) {

        # DataStore directory already exists
    }
    else {
        mkdir $path
            or die "Could not create DataStore directory $path\n";
    }

    # Add trailing slash if needed
    if ( !( $path =~ /(.)\/$/ ) ) {
        $path .= '/';
    }

    $_PATH = $path;    # the path where DataStore will be located
}


# full_path(id):
#       Auxiliary function to get the full path of the file where
#       object identified by $id may be stored.
#       This method should not be called from outside this class.
sub _full_path {
    my $id   = shift;

    defined($id) or die "Error in call to full_path()\n";

    return $_PATH . $id . '.db';
}

# Returns an instance of object identified by $id.
# Object existence may be checked using exists($id) or list_id()
# prior to calling load().
sub load {
    my ($id) = @_;

    my $data;
    if ( defined $id && -e _full_path($id) ) {

        #$data = retrieve($id.'.db') or die;
        $data = require( _full_path($id) );
    }
    return $data;
}

# Save object identified by $id in DataStore
sub save {
    my ( $id, $data ) = @_;
    if ( defined $id && defined $data ) {

        open my $out, ">", _full_path($id) or die;
        print $out Dumper($data);
        close $out;
    }
}

# Check wether object identified by $id is currently stored in DataStore
sub exists {
    my ($id) = shift;

    if ( -e _full_path($id) ) {
        return 1;
    }
    return 0;
}

# Returns a list of all object id's stored in DataStore
sub list_id {
    my @list;
    my $path  = $_PATH;
    my @files = <$path.*.'.db'>;
    foreach (@files) {
        my ( $id, $dummy ) = split( /\./, $_ );   # remove ".db" from filename
        push @list, $id;
    }
    return @list;
}

sub remove {
    my $id   = shift;

    if ( DataStore->exists($id) ) {
        unlink _full_path($id)
            or die " Could not remove persistent object $id\n ";
    }
}

sub next_id {
    my ($kind) = @_;
    my $data   = 1;
    if ( defined $kind ) {
        if ( -e $db_path . '/next_' . $kind ) {
            $data = require( $db_path . '/next_' . $kind );
            $data++;
        }
        open my $out, ">", $db_path . '/next_' . $kind or die;
        print $out Dumper($data);
        close $out;
        return $data;
    }
    else {
        return undef;
    }
}


1;
