# Resource class definition
package Resource;
use XML::LibXML;
use DataStore; 
use Data::Dumper;


# Create a new resource or fail if a resource exists in the
# datastore with the required identifier.
sub new {
    my $class = shift;
    my ( $id, $description, $granularity, $agenda ) = @_;

    return undef
        if ( !defined($id) || !defined($description) || !defined($granularity) )
        ;    # $ag argument is not mandatory
    return undef if DataStore->exists($id);

    my $obj;
    my $data;

    # Load on runtime to get rid of cross-dependency between
    # both Resource and Agenda
    require Agenda;

    $obj = {
        id   => $id,
        description => $description,
        granularity  => $granularity,
        agenda   => ( defined $agenda ) ? $agenda : Agenda->new(),
    };

    bless $obj, $class;
}

# Setters and getters
sub id {
    my $self = shift;
    if (@_) { $self->{id} = shift; }
    return $self->{id};
}

sub description {
    my $self = shift;
    if (@_) { $self->{description} = shift; }
    return $self->{description};
}

sub granularity {
    my $self = shift;
    if (@_) { $self->{granularity} = shift; }
    return $self->{granularity};
}

sub agenda {
    my $self = shift;
    if (@_) { $self->{agenda} = shift; }
    return $self->{agenda};
}

# Constructor that fetchs a resource from datastore
# or fail if not exists
sub load {
    my $class = shift;
    my ($id) = @_;

    return undef if ( !defined($id) );

    my $data = DataStore->load($id);

    return undef if ( !defined($data) );

    return Resource->from_xml($data);
}

# from_xml: creates a Resource via an XML string
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
            description => $dom->getElementsByTagName('description')->string_value,
            granularity  => $dom->getElementsByTagName('granularity')->string_value,
            agenda   => Agenda->new()
        };

        if ( $dom->getElementsByTagName('agenda')->get_node(1) ) {
            $obj->{agenda} = Agenda->from_xml(
                $dom->getElementsByTagName('agenda')->get_node(1)->toString );
        }
    }
    bless $obj, $class;
}

sub to_xml {
    my $self = shift;

    my $xml .= "<resource>";
    $xml    .= "<id>" . $self->{id} . "</id>";
    $xml    .= "<description>" . $self->{description} . "</description>";
    $xml    .= "<granularity>" . $self->{granularity} . "</granularity>";
    $xml    .= $self->{agenda}->to_xml()
        if defined $self->{agenda} && defined $self->{agenda}->elements();
    $xml .= "</resource>";
    return $xml;
}

sub list_id {
    my $self = shift;
    return DataStore->list_id;
}

# Save Resource in DataStore
sub save {
    my $self = shift;
    DataStore->save( $self->{id}, $self->to_xml() );
}

sub DESTROY {
    my $self = shift;
    $self->save;
}

sub next_id {
    my $self = shift;
    return DataStore->next_id($self);
}

1;
