use strict;
use warnings;

use Path::Class qw( file );
use File::Copy qw( copy );

BEGIN {
    if ( !exists $ENV{'TESTING_DB'} ) {
        my $db     = 'smeagol.db';
        my $source = file( 't', $db );

        $ENV{'TMPDIR'    } ||= '/tmp';
        $ENV{'TESTING_DB'} ||= file( $ENV{'TMPDIR'}, $db );

        copy( $source, $ENV{'TESTING_DB'} );
    }
}

1;
