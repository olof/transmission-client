package Transmission::AttributeRole;

=head1 NAME

Transmission::AttributeRole - For Torrent and Client

=head1 DESCRIPTION

This role is used by L<Transmission::Client> and L<Transmission::Torrent>.
It requires the consuming class to provide the method C<read_all()>.

=cut

use Moose::Role;

=head1 ATTRIBUTES

=head2 client

 $obj = $self->client;

Returns a L<Transmission::Client> object.

=cut

has client => (
    is => 'ro',
    isa => 'Object',
    handles => { client_error => 'error' },
);

=head2 lazy_write

 $bool = $self->lazy_write;
 $self->lazy_write($bool);

Will prevent writeable attributes from sending a request to Transmission.
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
This will again populate all (or most) attributes right after the object is
constructed (if Transmission answers the request).

=cut

has eager_read => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
    trigger => sub { $_[0]->read_all if($_[1]) },
);

# this method name exists to prove a point - not to be readable...
sub _camel2Normal {
    shift;
    local $_ = shift;
    tr/_/-/;
    s/([A-Z]+)/{ "_" .lc($1) }/ge;
    return $_;
}

# this method name exists to prove a point - not to be readable...
sub _translateCamel {
    my $self = shift;
    my $h = shift;

    for my $camel (keys %$h) {
        my $key = $self->_camel2Normal($camel);

        if(my $tr = $self->can("_translate_$key")) {
            $h->{$key} = $tr->( delete $h->{$camel} );
        }
        else {
            $h->{$key} = delete $h->{$camel};
        }

        if(ref $h->{$key} eq 'HASH') {
            $self->_translateCamel($h->{$key});
        }
    }
}

sub _translate_status {
    return 'queued'      if($_[0] == 1);
    return 'checking'    if($_[0] == 2);
    return 'downloading' if($_[0] == 4);
    return 'seeding'     if($_[0] == 8);
    return 'stopped'     if($_[0] == 16);
    return $_[0];
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
