package Transmission::Session::Stats;

=head1 NAME

Transmission::Session::Stats - Transmission session statistics

=head1 DESCRIPTION

See "4.2 Sesion statistics" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

=cut

use Moose;

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=cut

BEGIN {
    my %both = qw/
        activeTorrentCount  Num
        downloadSpeed       Num
        pausedTorrentCount  Num
        torrentCount        Num
        uploadSpeed         Num
    /;

    __PACKAGE__->meta->add_method(read_all => sub {
    });
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>

=cut

1;
