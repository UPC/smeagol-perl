# Un recurs (les dades que corresponen)
package Resource;
use XML::LibXML;
use DataStore ();
use Data::Dumper;

sub new {
    my $class = shift;
    my ($id, $desc, $gra, $ag) = @_;

    my $obj = {};
    my $data = DataStore->load($id);
	
	if ($data){
	    $obj = Resource->from_xml($data);
	}else{
	    # Load on runtime to get rid of cross-dependency between
	    # both Resource and Agenda
	    require Agenda;
	
    	    $obj = {
    	        id => $id,
    	        desc => $desc,
    	        gra => $gra,
    	        ag => $ag ? $ag : Agenda->new(),
    	    };
	}
    bless $obj, $class;
}

# from_xml: creates a Resource via an XML string
# (XML validation not yet implemented)
sub from_xml {
    my $class = shift;
    my $xml = shift;
    
    my $obj = {};
    my $data = DataStore->load($id);
	
    if ($data){
	$obj = Resource->from_xml($data);
    }else{
	# Load on runtime to get rid of cross-dependency between
	# both Resource and Agenda
	require Agenda;
    
	# validate XML string against the DTD
	my $dtd = XML::LibXML::Dtd->new(
            "CPL UPC//Resource DTD v0.01",
            "http://devel.cpl.upc.edu/recursos/export/HEAD/angel/xml/resource.dtd");

        my $dom = XML::LibXML->new->parse_string($xml);

        if (!$dom->is_valid($dtd)) {
            # validation failed
            return 0;
        }

        $obj = {
            id   => $dom->getElementsByTagName('id')->string_value, 
            desc => $dom->getElementsByTagName('description')->string_value,
            gra  => $dom->getElementsByTagName('granularity')->string_value,
            ag   => Agenda->new() 
        };

        if ($dom->getElementsByTagName('agenda')->get_node(1)) {
            $obj->{ag} = Agenda->from_xml(
                $dom->getElementsByTagName('agenda')->get_node(1)->toString);
        }
    }
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
	DataStore->save($self->{id},$self->to_xml());
}

1;
