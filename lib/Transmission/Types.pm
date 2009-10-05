package Transmission::Types;

=head1 NAME

Transmission::Types - Moose types for Transmission

=head1 DESCRIPTION

The types below is pretty much what you would expect them to be, execpt
for some (maybe weird?) default values - that is for coercion from "Any".

=head1 TYPES

=head2 number

=head2 double

=head2 string

=head2 boolean

=head2 array

=cut

use MooseX::Types -declare => [qw/number double string boolean array/];
use MooseX::Types::Moose ':all';

subtype number, as Num;
coerce number, from Any, via { -1 };

subtype double, as Num;
coerce double, from Any, via { -1 };

subtype string, as Str;
coerce string, from Any, via { defined $_ ? "$_" : "__UNDEF__" };

subtype boolean, as Bool;
coerce boolean, from Object, via { int $_ };

subtype array, as ArrayRef;
coerce array, from Any, via { [] };

=head1 LICENSE

=head1 NAME

See L<Transmission::Client>

=cut

1;
