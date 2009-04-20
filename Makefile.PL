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

test_requires 'Test::More'           => 0;
test_requires 'Data::Compare'        => 0;

install_script 'bin/smeagol-client';
install_script 'bin/smeagol-server';

# t and inc are also added
no_index directory => qw( doc dtd xsl css );

WriteAll;
