package Transmission::AttributeRole;

=head1 NAME

Transmission::AttributeRole - For Torrent and Client

=cut

use Moose::Role;

requires 'read_all';

=head2 client

 $obj = $self->client;

Returns a L<Transmission::Client> object.

=cut

has client => (
    is => 'ro',
    isa => 'Object',
    required => 1,
);

=head2 lazy_write

 $bool = $self->lazy_write;

Will prevent writeable attributes to send a request to transmission.
L</write_all()> can then be used to sync data.

=cut

has lazy_write => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

=head2 eager_read

 $bool = $self->eager_read;

Setting this attribute in constructor forces L</read_all()> to be called.

=cut

has eager_read => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    trigger => sub { $_[0]->read_all if($_[1]) },
);

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
