package V2::Server::Obj::Resource;

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Params::Validate;

subtype 'ValidId' => as 'Int' => where { $_ >= 0 } => message { 'The id is not valid' };
subtype 'ValidInfo' => as 'Str' => where { length($_) <= 128 } => message { 'The info parameter is not valid' };
subtype 'ValidDesc' => as 'Str' => where { length($_) <= 256 } => message { 'The description parameter is not valid' };

has 'id'          => ( isa => 'ValidId',       is => 'ro' );
has 'info'        => ( isa => 'ValidInfo',     is => 'rw' );
has 'description' => ( isa => 'ValidDesc',     is => 'rw' );

__PACKAGE__->meta->make_immutable;

1;