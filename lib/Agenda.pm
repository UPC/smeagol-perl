package Agenda;

use Set::Object ();
use base qw(Set::Object);

sub new {
    my $class = shift;

    my $obj = $class->SUPER::new();

    bless $obj, $class;
}

sub append {
    my $self = shift;
    my ($slot) = @_;

    $self->insert($slot)
        unless $self->interlace($slot);
}

sub interlace {
    my $self = shift;
    my ($slot) = @_;

    return grep { $slot->intersects($_) } $self->elements;
}

sub to_xml {
    my $self = shift;

    my $xml = "<agenda>";
    for my $slot ( $self->elements ) {
        $xml .= $slot->to_xml();
    }
    $xml .= "</agenda>";

    return $xml;
}
        
1;
