use inc::Module::Install;
use Module::Install::Catalyst;

name 'V2-Server';

all_from 'lib/V2/Server.pm';

license 'agpl_3';

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
requires 'Exception::Class::TryCatch' => 0;

test_requires 'Path::Class'         => 0;
test_requires 'File::Copy'          => 0;
test_requires 'Test::More'          => 0;
test_requires 'Data::Compare'       => 0;
test_requires 'Test::Pod'           => 0;
test_requires 'Test::Pod::Coverage' => 0;
test_requires 'Data::Dumper::Simple' => 0;
test_requires 'JSON'                => 0;
test_requires 'List::Compare'       => 0;
test_requires 'utf8::all'           => 0;
test_requires 'Text::CSV'           => 0;

catalyst;

# install new v2 scripts
install_script glob 'script/*';

# do not include in CPAN index
no_index directory => qw( doc );

auto_install;
WriteAll;
