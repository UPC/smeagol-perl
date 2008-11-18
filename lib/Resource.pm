# Un recurs (les dades que corresponen)
package Resource;
use XML::Simple;
use Data::Dumper;
use DataStore ();

sub new {
    my $class = shift;
    my ($id, $desc, $gra) = @_;

    # Load on runtime to get rid of cross-dependency between
    # both Resoure and Agenda
    require Agenda;

    my $obj = {
        id => $id,
        desc => $desc,
        gra => $gra,
        ag => Agenda->new(),
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
        gra => $doc->{granularity},
        ag => Agenda->new(),
    };

    bless $obj, $class;
}

sub to_xml {
    my $self = shift;

    my $xml .= "<resource>";
    $xml .= "<id>" . $self->{id} . "</id>";
    $xml .= "<description>" . $self->{desc} . "</description>";
    $xml .= "<granularity>" . $self->{gra} . "</granularity>";
    $xml .= $self->{ag}->to_xml()
        if defined $self->{ag} && defined $self->{ag}->elements();
    $xml .= "</resource>";
    return $xml;
}

sub DESTROY {
    my $self = shift;
    DataStore->save();
}

1;
