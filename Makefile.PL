use inc::Module::Install;

name 'Smeagol';

all_from 'lib/Smeagol.pm';

license 'agpl';

requires 'DateTime'                  => 0;
requires 'DateTime::Span'            => 0;
requires 'Set::Object'               => 0;
requires 'XML::LibXML'               => 0;
requires 'XML::Simple'               => 0;
requires 'HTTP::Server::Simple::CGI' => 0;
requires 'Data::ICal'                => 0;
requires 'Date::ICal'                => 0;
requires 'Getopt::Euclid'            => 0;
requires 'File::Path'                => 0;
requires 'HTTP::Status'              => 5.817;

test_requires 'Test::More'    => 0;
test_requires 'Data::Compare' => 0;

install_script 'bin/smeagol-client';
install_script 'bin/smeagol-server';

install_share;

# share, t and inc are also added
no_index directory => qw( doc dtd );

WriteAll;

# FIXME: symlink may not exist on this platform but it is used
#        as a work-around until File::ShareDir support is added
#        (ticket:34)
my $dtd = "dtd";
( unlink $dtd or die "cannot remove $dtd: $!" )
    if -e $dtd;

symlink "share/$dtd", $dtd
    or die "cannot symlink $dtd: $!";
