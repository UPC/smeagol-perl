# Un recurs (les dades que corresponen)
package Resource;
use XML::Simple;

sub new {
    my $class = shift;
    my ($id, $desc, $gra) = @_;

    my $obj = {
        id => $id,
        desc => $desc,
	gra => $gra,
    };

    bless $obj, $class;
}


# from_xml: creates a Resource via an XML string
# (XML validation not yet implemented)
sub from_xml {
    my $class = shift;
    my $xml = shift;

    my $doc = XMLin($xml);
    my $obj = {
        id => $doc->{id}, 
        desc => $doc->{description},
	gra => $doc->{granularity}
    };

    bless $obj, $class;
}

sub to_xml {
    my $self = shift;

    my $xml = "<resource>";
    $xml .= "<id>" . $self->{id} . "</id>";
    $xml .= "<description>" . $self->{desc} . "</description>";
    $xml .= "<granularity>" . $self->{gra} . "</granularity>";
    $xml = "</resource>";

    return $xml;
}


# Bookable resource
package Resource::Bookable;

sub new {
    my $class = shift;

    my $obj = {};

    bless $obj, $class;
}

1;
