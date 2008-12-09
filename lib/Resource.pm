# Resource class definition
package Resource;
use XML::LibXML;
use DataStore ();
use Data::Dumper;

# DataStore PATH should be defined externally
# in a configuration file (smeagol.conf ?)
$resource_datastore_path = '/tmp/smeagol_datastore';

my $datastore = DataStore->new($resource_datastore_path);

# Create a new resource or fail if a resource exists in the
# datastore with the required identifier.
sub new {
    my $class = shift;
    my ( $id, $desc, $gra, $ag ) = @_;

    return undef
        if ( !defined($id) || !defined($desc) || !defined($gra) )
        ;    # $ag argument is not mandatory
    return undef if $datastore->exists($id);

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

# Setters and getters
sub id {
    my $self = shift;
    if (@_) { $self->{id} = shift; }
    return $self->{id};
}

sub desc {
    my $self = shift;
    if (@_) { $self->{desc} = shift; }
    return $self->{desc};
}

sub gra {
    my $self = shift;
    if (@_) { $self->{gra} = shift; }
    return $self->{gra};
}

sub ag {
    my $self = shift;
    if (@_) { $self->{ag} = shift; }
    return $self->{ag};
}

# Constructor that fetchs a resource from datastore
# or fail if not exists
sub load {
    my $class = shift;
    my ($id) = @_;

    return undef if ( !defined($id) );

    my $data = $datastore->load($id);

    return undef if ( !defined($data) );

    return Resource->from_xml($data);
}

# from_xml: creates a Resource via an XML string
# (XML validation not yet implemented)
sub from_xml {
    my $class = shift;
    my $xml   = shift;

    my $obj  = {};
    my $data = $datastore->load($id);

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

sub list_id {
    my $self = shift;
    return $datastore->list_id;
}

# Save Resource in DataStore
sub save {
    my $self = shift;
    $datastore->save( $self->{id}, $self->to_xml() );
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
