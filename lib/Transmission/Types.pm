package Transmission::Types;

=head1 NAME

Transmission::Types - Moose types

=cut

use MooseX::Types -declare => [qw/number double string boolean array/];
use MooseX::Types::Moose ':all';

subtype number, as Num;
coerce number, from Any, via { 0 };

subtype double, as Num;
coerce double, from Any, via { 0 };

subtype string, as Str;
coerce string, from Any, via { '' };

subtype boolean, as Bool;
coerce boolean, from Object, via { int $_ };

subtype array, as ArrayRef;
coerce array, from Any, via { [] };

=head1 LICENSE

=head1 NAME

See L<Transmission::Client>

=cut

1;
