# Un recurs (les dades que corresponen)
package Resource;
use XML::Simple;

sub new {
    my $class = shift;
    my ($id, $desc) = @_;

    my $obj = {
        id => $id,
        desc => $desc,
    };

    bless $obj, $class;
}


# from_xml: creates a Resource via an XML string
# (XML validation not yet implemented)
sub from_xml {
    my $class = shift;
    my $xml = shift;

    my $doc = XMLin($xml);
    #my $doc = XMLin("<resource><id>aula</id><desc>Aula chachipiruli</desc></resource>");
    my $obj = {
        id => $doc->{id}, 
        desc => $doc->{description}
    };

    bless $obj, $class;
}


# Bookable resource
package Resource::Bookable;

sub new {
    my $class = shift;

    my $obj = {};

    bless $obj, $class;
}

1;
