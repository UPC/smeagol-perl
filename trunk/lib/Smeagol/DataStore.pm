package Smeagol::DataStore;

use strict;
use warnings;

use Data::Dumper;
use File::Path;
use Carp;
use Encode;

my $_PATH;
my $DEFAULT_DS_PATH = '/tmp/smeagol_datastore/';

# init($path): sets DataStore storage path.
#       $path argument indicates the directory
#       where persistent files will be stored.
#       $path directory will be created, if needed.
sub init {
    my ($path) = @_;

    $path = $DEFAULT_DS_PATH
        unless defined $path;

    croak "Cannot use the root directory"
        if $path eq "/";

    # Create the path, if needed
    if ( !-d $path ) {
        eval { File::Path::mkpath($path) };
        croak "Could not create DataStore directory $path"
            if $@;
    }

    # Add trailing slash if needed
    $path .= '/'
        if $path !~ /(.)\/$/;

    # the path where DataStore will be located
    $_PATH = $path;
}

# full_path(id):
#       Auxiliary function to get the full path of the file where
#       object identified by $id may be stored.
#       This method should not be called from outside this class.
sub _getFullPath {
    my ($id) = @_;

    defined($id) or confess "Error in call to full_path()";

    return $_PATH . $id . '.db';
}

# Returns an instance of object identified by $id.
# Object existence may be checked using exists($id) or getIDList()
# prior to calling load().
sub load {
    my $self = shift;
    my ($id) = @_;

    croak "undefined id in call to load()"
        unless defined $id;

    my $data;
    if ( defined $id && -e _getFullPath($id) ) {

        # I mean do EXPR not do SUB, hence the + sign
        $data = do +_getFullPath($id);
    }
    return decode( "UTF-8", $data );
}

# Save object identified by $id in DataStore
sub save {
    my $self = shift;
    my ( $id, $data ) = @_;

    croak "undefined id in call to save()"
        unless defined $id;

    if ( defined $id && defined $data ) {
        open my $out, ">", _getFullPath($id)
            or croak "cannot open " . _getFullPath($id);
        print $out Dumper( encode( "UTF-8", $data ) );
        close $out;
    }
}

# Check wether object identified by $id is currently stored in DataStore
sub exists {
    my $self = shift;
    my ($id) = shift;

    if ( -e _getFullPath($id) ) {
        return 1;
    }
    return 0;
}

# Returns a list of all object id's stored in DataStore
sub getIDList {
    my $self = shift;

    my @list;
    my $path = $_PATH;

    foreach ( glob "$path*.db" ) {
        my $id = $_;

        # FIXME: regex should be more specific, fails if $path contains
        #        numbers, e.g. /home/datastore/2009
        #        (ticket:138)
        $id =~ s/\D//g;

        push @list, $id;
    }
    return @list;
}

sub remove {
    my $self = shift;
    my ($id) = @_;

    if ( Smeagol::DataStore->exists($id) ) {
        unlink _getFullPath($id)
            or croak "Could not remove persistent object "
            . _getFullPath($id);
    }
}

sub getNextID {
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
        return;
    }
}

sub clean {
    my $self = shift;

    File::Path::rmtree($_PATH);
}

1;
