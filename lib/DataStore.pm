package DataStore;
use Data::Dumper;

# new($path): DataStore constructor. $path argument indicates the directory
#       where persistent files will be stored.
#       $path directory will be created, if needed.
sub new {
    my $class = shift;
    my $path  = shift;

    defined($path) or die "DataStore->new() needs an argument!\n";

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

    my $obj = {
        PATH => $path,    # the path where DataStore will be located
    };

    bless $obj, $class;
}

# full_path(id):
#       Auxiliary function to get the full path of the file where
#       object identified by $id may be stored.
#       This method should not be called from outside this class.
sub full_path {
    my $self = shift;
    my $id   = shift;

    defined($id) or die "Error in call to full_path()\n";

    return $self->{PATH} . $id . '.db';
}

# Returns an instance of object identified by $id.
# Object existence may be checked using exists($id) or list_id()
# prior to calling load().
sub load {
    my $self = shift;
    my ($id) = @_;

    my $data;
    if ( defined $id && -e full_path($id) ) {

        #$data = retrieve($id.'.db') or die;
        $data = require( full_path($id) );
    }
    return $data;
}

# Save object identified by $id in DataStore
sub save {
    my $self = shift;
    my ( $id, $data ) = @_;
    if ( defined $id && defined $data ) {

        #nstore(\$data, $id.'.db') or die;
        open my $out, ">", $db_path . $id . '.db' or die;
        print $out Dumper($data);
        close $out;
    }
}

# Check wether object identified by $id is currently stored in DataStore
sub exists {
    my $self = shift;
    my ($id) = @_;

    if ( -e full_path($id) ) {
        return 1;
    }
    return 0;
}

# Returns a list of all object id's stored in DataStore
sub list_id {
    my $self = shift;

    my @list;
    my $path  = $self->{PATH};
    my @files = <$path.*.'.db'>;
    foreach (@files) {
        my ( $id, $dummy ) = split( /\./, $_ );   # remove ".db" from filename
        push @list, $id;
    }
    return @list;
}

sub remove {
    my $self = shift;
    my $id   = shift;

    if ( $self->exists($id) ) {
        unlink full_path($id)
            or die " Could not remove persistent object $id\n ";
    }
}

sub next_id {
    my $self   = shift;
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
