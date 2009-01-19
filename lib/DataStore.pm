package DataStore;

use strict;
use warnings;

use Data::Dumper;
use File::Path;
use Carp;

my $_PATH;

init('/tmp/smeagol_datastore/');

# init($path): sets DataStore storage path.
#       $path argument indicates the directory
#       where persistent files will be stored.
#       $path directory will be created, if needed.
sub init {
    my $path = shift;

    defined($path) or die "DataStore->init() needs an argument!";

    if ( $path eq "/" ) {
        $path = "/tmp/smeagol_datastore/";
    }

    # Create the path, if needed
    if ( -d $path ) {

        # DataStore directory already exists
    }
    else {
        mkdir $path
            or die "Could not create DataStore directory $path";
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
    my $id = shift;

    defined($id) or confess "Error in call to full_path()";

    return $_PATH . $id . '.db';
}

# Returns an instance of object identified by $id.
# Object existence may be checked using exists($id) or list_id()
# prior to calling load().
sub load {
    my $self = shift;
    my ($id) = @_;

    defined ($id) or die "undefined id in call to load()";

    my $data;
    if ( defined $id && -e _full_path($id) ) {
        # I mean do EXPR not do SUB, hence the + sign
        $data = do +_full_path($id);
    }
    return $data;
}

# Save object identified by $id in DataStore
sub save {
    my $self = shift;
    my ( $id, $data ) = @_;

    defined($id) or die "undefined id in call to save()";

    if ( defined $id && defined $data ) {
        open my $out, ">", _full_path($id) or die;
        print $out Dumper($data);
        close $out;
    }
}

# Check wether object identified by $id is currently stored in DataStore
sub exists {
    my $self = shift;
    my ($id) = shift;

    if ( -e _full_path($id) ) {
        return 1;
    }
    return 0;
}

# Returns a list of all object id's stored in DataStore
sub list_id {
    my $self = shift;
    my @list;
    my $path  = $_PATH;
	foreach (glob "$path*.db") {
    	my $id = $_;
    	$id=~ s/\D//g;
        #my ( $id, $dummy ) = split( /\./, $_ );   # remove ".db" from filename
        push @list, $id;
    }
    return @list;
}

sub remove {
    my $self = shift;
    my $id = shift;

    if ( DataStore->exists($id) ) {
        unlink _full_path($id)
            or die " Could not remove persistent object $id\n ";
    }
}

sub next_id {
    my $self = shift;
    my ($kind) = @_;
    my $data = 1;
	my $path = $_PATH . 'next_' . $kind;
    if ( defined $kind ) {
        if ( -e $path ) {
            $data = do $path;
            $data++;
        }
        open my $out, ">", $path or confess "$_PATH $! !!!";
        print $out Dumper($data);
        close $out;
        return $data;
    }
    else {
        return undef;
    }
}

sub clean {
    my $self = shift;
    File::Path->rmtree($_PATH);
}

1;
