# Un recurs (les dades que corresponen)
package Resource;
use XML::LibXML;
use DataStore ();
use Data::Dumper;

# Create a new resource or fail if a resource exists in the 
# datastore with the required identifier.
sub new {
    my $class = shift;
    my ( $id, $desc, $gra, $ag ) = @_;

    return undef
        if ( !defined($id) || !defined($desc) || !defined($gra) )
        ;    # $ag argument is not mandatory
    return undef if DataStore->exists($id)
    
    my $obj;
    my $data;

    # Load on runtime to get rid of cross-dependency between
    # both Resource and Agenda
    require Agenda;

    $obj = {
	id   => $id,
	desc => $desc,
	gra  => $gra,
	ag   => ( defined $ag ) ? $ag : Agenda->new(),
    };

    bless $obj, $class;
}


# Constructor that fetchs a resource from datastore 
# or fail if not exists
sub fetch {
    my $class = shift;
    my ( $id ) = @_;

    return undef if (!defined($id))

    my $obj;
    my $data = DataStore->load($id);

    return undef if (!defined($data))

    $obj = Resource->from_xml($data);

    bless $obj, $class;
}




# from_xml: creates a Resource via an XML string
# (XML validation not yet implemented)
sub from_xml {
    my $class = shift;
    my $xml   = shift;

    my $obj  = {};
    my $data = DataStore->load($id);

    if ($data) {
        $obj = Resource->from_xml($data);
    }
    else {

        # Load on runtime to get rid of cross-dependency between
        # both Resource and Agenda
        require Agenda;

        # validate XML string against the DTD
        my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Resource DTD v0.01",
            "http://devel.cpl.upc.edu/recursos/export/HEAD/angel/xml/resource.dtd"
        );

        my $dom = eval { XML::LibXML->new->parse_string($xml) };

        if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

            # validation failed
            return undef;
        }

        $obj = {
            id   => $dom->getElementsByTagName('id')->string_value,
            desc => $dom->getElementsByTagName('description')->string_value,
            gra  => $dom->getElementsByTagName('granularity')->string_value,
            ag   => Agenda->new()
        };

        if ( $dom->getElementsByTagName('agenda')->get_node(1) ) {
            $obj->{ag} = Agenda->from_xml(
                $dom->getElementsByTagName('agenda')->get_node(1)->toString );
        }
    }
    bless $obj, $class;
}

sub to_xml {
    my $self = shift;

    my $xml .= "<resource>";
    $xml    .= "<id>" . $self->{id} . "</id>";
    $xml    .= "<description>" . $self->{desc} . "</description>";
    $xml    .= "<granularity>" . $self->{gra} . "</granularity>";
    $xml    .= $self->{ag}->to_xml()
        if defined $self->{ag} && defined $self->{ag}->elements();
    $xml .= "</resource>";
    return $xml;
}

sub DESTROY {
    my $self = shift;
    DataStore->save( $self->{id}, $self->to_xml() );
}

1;
