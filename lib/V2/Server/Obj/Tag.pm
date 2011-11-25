package V2::Server::Obj::Tag;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;

subtype 'ValidDescTag' => as 'Str' => where { length($_) <= 256 } => message { 'The description parameter is not valid' };
subtype 'ValidIdTag' => as 'Str' => where { /\w+/ && / \A [\w.:_\-]{1,64} \z /xms } => message { 'The tag identifier is not valid' };

has 'id'          => ( isa => 'ValidIdTag',       is => 'ro' );
has 'description' => ( isa => 'ValidDescTag',     is => 'rw' );

__PACKAGE__->meta->make_immutable;

1;