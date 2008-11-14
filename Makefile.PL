use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'llesca1',
    VERSION           => '0.01',
    PREREQ_PM         => {
        'DateTime'       => undef,
        'DateTime::Span' => undef,
        'Set::Object'    => undef,
        'XML::LibXML'    => undef,
        'XML::Simple'    => undef,
        'HTTP::Server::Simple::CGI' => undef,
        'YAML::Tiny'                => undef,
        'Getopt::Long'   => undef
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Proves de la llesca1',
       AUTHOR         => 'Alex Muntada <alexm@alexm.org>') : ()),
);
