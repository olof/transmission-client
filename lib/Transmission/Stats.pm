package Transmission::Stats;

=head1 NAME

Transmission::Stats - Transmission session statistics

=head1 DESCRIPTION

See "4.2 Sesion statistics" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

=cut

use Moose;

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 active_torrent_count

 $num = $self->active_torrent_count;

=head2 download_speed

 $num = $self->download_speed;

=head2 paused_torrent_count

 $num = $self->paused_torrent_count;

=head2 torrent_count

 $num = $self->torrent_count;

=head2 upload_speed

 $num = $self->upload_speed;

=cut

BEGIN {
    my %both = qw/
        activeTorrentCount  Num
        downloadSpeed       Num
        pausedTorrentCount  Num
        torrentCount        Num
        uploadSpeed         Num
    /;

    for my $camel (keys %both) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'ro',
            isa => "Maybe[$both{$camel}]",
            writer => "_set_$name",
        );
    }

    __PACKAGE__->meta->add_method(read_all => sub {
        my $self = shift;
        my $lazy = $self->lazy_write;
        my $data;

        $data = $self->client->rpc('session-get') or return;

        $self->lazy_write(1);

        for my $camel (keys %$data) {
            (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        }

        $self->lazy_write($lazy);

        return 1;
    });
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
