# Resource class definition
package Resource;

use strict;
use warnings;

use XML::LibXML;
use DataStore;
use Data::Dumper;
use Carp;
use XML;

# Create a new resource
sub new {
    my $class = shift;
    my ( $description, $granularity, $agenda ) = @_;

    return
        if ( !defined($description)
        || !defined($granularity) );    # $ag argument is not mandatory

    my $obj;
    my $data;

    # Load on runtime to get rid of cross-dependency between
    # both Resource and Agenda
    require Agenda;

    $obj = {
        id          => _next_id(),
        description => $description,
        granularity => $granularity,
        agenda      => ( defined $agenda ) ? $agenda : Agenda->new(),
        _persistent => 0,
    };

    bless $obj, $class;
    return $obj;
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

sub url {
    my $self = shift;

    return "/" . lc(__PACKAGE__) . "/" . $self->id;
}

# Constructor that fetchs a resource from datastore
# or fail if it cannot be found
sub load {
    my $class = shift;
    my ($id) = @_;

    return if ( !defined($id) );

    my $data = DataStore->load($id);

    return if ( !defined($data) );

    my $resource = Resource->from_xml( $data, $id );

    return $resource;
}

# from_xml: creates a Resource via an XML string
# If $id is defined, it will be used as the Resource ID.
# Otherwise, a new ID will be generated by DataStore
sub from_xml {
    my $class = shift;
    my ( $xml, $id ) = @_;

    my $obj = {};

    # Load on runtime to get rid of cross-dependency between
    # both Resource and Agenda
    require Agenda;

    # validate XML string against the DTD
    my $dtd = XML::LibXML::Dtd->new( "CPL UPC//Resource DTD v0.03",
        "dtd/resource.dtd" );

    my $dom = eval { XML::LibXML->new->parse_string($xml) };

    if ( ( !defined $dom ) || !$dom->is_valid($dtd) ) {

        # validation failed
        return;
    }

    $obj = {
        id => ( ( defined $id ) ? $id : _next_id() ),
        description =>
            $dom->getElementsByTagName('description')->string_value,
        granularity =>
            $dom->getElementsByTagName('granularity')->string_value,
        agenda      => Agenda->new(),
        _persistent => 0,
    };

    if ( $dom->getElementsByTagName('agenda')->get_node(1) ) {
        $obj->{agenda} = Agenda->from_xml(
            $dom->getElementsByTagName('agenda')->get_node(1)->toString );
    }
    bless $obj, $class;
    return $obj;
}

sub to_xml {
    my $self = shift;
    my ( $url, $isRootNode ) = @_;

    $url .= $self->url
        if defined $url;

    my $xmlText = "<resource>";
    $xmlText .= "<description>" . $self->{description} . "</description>";
    $xmlText .= "<granularity>" . $self->{granularity} . "</granularity>";

    $xmlText .= $self->{agenda}->to_xml($url)
        if ( ( defined $self->{agenda} )
        && defined( $self->{agenda}->elements ) );

    $xmlText .= "</resource>";

    return $xmlText
        unless defined $url && $url ne '';

    my $xmlDoc = eval { XML->new($xmlText) };
    croak $@ if $@;

    $xmlDoc->addXLink( "resource", $url );
    if ($isRootNode) {
        $xmlDoc->addPreamble("resource");
        return "$xmlDoc";
    }
    else {

        # Take the first node and skip processing instructions
        my $node = $xmlDoc->doc->getElementsByTagName("resource")->[0];
        return $node->toString;
    }
}

sub list_id {
    my $self = shift;

    return DataStore->list_id;
}

sub remove {
    my $self = shift;

    DataStore->remove( $self->{id} );
    $self->{_persistent} = 0;
}

# Save Resource in DataStore
sub save {
    my $self = shift;

    $self->{_persistent} = 1;
    DataStore->save( $self->{id}, $self->to_xml() );
}

sub DESTROY {
    my $self = shift;

    $self->save if ( $self->{_persistent} );
}

sub _next_id {
    return DataStore->next_id(__PACKAGE__);
}

1;
