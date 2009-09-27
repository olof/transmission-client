package Transmission::Torrent::File;

=head1 NAME

Transmission::Torrent::File

=cut

use Moose;
use Transmission::Types ':all';

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 key

 $str = $self->key;

=head2 length

 $num = $self->length;

=head2 name

 $str = $self->name;

=head2 bytes_completed

 $num = $self->bytes_completed;

=head2 wanted

 $bool = $self->wanted;

=head2 priority

 $num = $self->priority;

=cut

{
    my %read = (
        key             => string,
        length          => number,
        name            => string,
        bytesCompleted  => number,
        wanted          => boolean,
        priority        => number,
    );

    for my $camel (keys %read) {
        my $name = __PACKAGE__->_camel2Normal($camel);
        has $name => (
            is => 'ro',
            isa => $read{$camel},
            writer => "_set_$name",
        );
    }
}

=head1 METHODS

=head2 BUILDARGS

=cut

sub BUILDARGS {
    my $self = shift;
    my $args = $self->SUPER::BUILDARGS(@_);

    for my $camel (keys %$args) {
        my $key = __PACKAGE__->_camel2Normal($camel);
        $args->{$key} = delete $args->{$camel};
    }

    return $args;
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
