use inc::Module::Install;
use Module::Install::Catalyst;

name 'V2-Server';

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

requires 'Catalyst::View::JSON'             => 0;
requires 'Catalyst::Model::DBIC::Schema'    => 0;
requires 'Catalyst::Plugin::Unicode'        => 0;
requires 'Catalyst::Plugin::Static::Simple' => 0;
requires 'Catalyst::Plugin::ConfigLoader'   => 0;
requires 'Catalyst::View::TT'               => 0;
requires 'Catalyst::Controller::REST'       => 0;
requires 'DBIx::Class'                      => 0;
requires 'DBIx::Class::TimeStamp'           => 0;
requires 'Catalyst::Action::RenderView'     => 0;
requires 'DateTime::Format::SQLite'         => 0;
requires 'DateTime::Event::ICal'            => 0;
requires 'DBD::SQLite'                      => 0;

test_requires 'Test::More'          => 0;
test_requires 'Data::Compare'       => 0;
test_requires 'Test::Pod'           => 0;
test_requires 'Test::Pod::Coverage' => 0;

catalyst;

# don't install old v1 scripts from bin
#install_script glob 'bin/*';

# install new v2 scripts
install_script glob 'script/*';

# don't install old share
#install_share;

# share, t and inc are also added
no_index directory => qw( doc dtd );

auto_install;
WriteAll;

# FIXME: symlink may not exist on this platform but it is used
#        as a work-around until File::ShareDir support is added
#        (ticket:34)
my $dtd = "dtd";
( unlink $dtd or die "cannot remove $dtd: $!" )
    if -e $dtd;

symlink "share/$dtd", $dtd
    or die "cannot symlink $dtd: $!";
