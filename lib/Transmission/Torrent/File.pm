package Transmission::Torrent::File;

=head1 NAME

Transmission::Torrent::File

=cut

use Moose;

=head1 ATTRIBUTES

=head2 key

 $str = $self->key;

=head2 length

 $num = $self->length;

=head2 name

 $str = $self->name;

=head2 bytes_completed

 $num = $self->bytes_completed;

=heaa2 wanted

 $bool = $self->wanted;

=head2 priority

 $num = $self->priority;

=cut

{
    my %read = qw/
        key             Str
        length          Num
        name            Str
        bytesCompleted  Num
        wanted          Bool
        priority        Num
    /;

    for my $camel (keys %read) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'ro',
            isa => "Maybe[$read{$camel}]",
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
        (my $key = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        $args->{$key} = "" .delete $args->{$camel};
        $args->{$key} = 1 if($args->{$key} eq 'true');
        $args->{$key} = 0 if($args->{$key} eq 'false');
    }

    return $args;
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
