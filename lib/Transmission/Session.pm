package Transmission::Session;

=head1 NAME

Transmission::Session - Transmission session

=head1 DESCRIPTION

See "4 Session requests" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

This class holds data, regarding the Transmission session.

=cut

use Moose;
use Transmission::Stats;

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 stats

 $stats_obj = $self->stats;
 
Returns a L<Transmission::Stats> object.

=cut

has stats => (
    is => 'ro',
    isa => 'Object',
    lazy => 1,
    default => sub {
        Transmission::Stats->new(client => $_[0]->client);
    }
);

=head2 alt_speed_down

 $number = $self->alt_speed_down

max global download speed (in K/s)

=head2 alt_speed_enabled

 $boolean = $self->alt_speed_enabled

true means use the alt speeds

=head2 alt_speed_time_begin

 $number = $self->alt_speed_time_begin

when to turn on alt speeds (units: minutes after midnight)

=head2 alt_speed_time_enabled

 $boolean = $self->alt_speed_time_enabled

true means the scheduled on/off times are used

=head2 alt_speed_time_end

 $number = $self->alt_speed_time_end

when to turn off alt speeds (units: same)

=head2 alt_speed_time_day

 $number = $self->alt_speed_time_day

what day(s) to turn on alt speeds (look at tr_sched_day)

=head2 alt_speed_up

 $number = $self->alt_speed_up

max global upload speed (in K/s)

=head2 blocklist_enabled

 $boolean = $self->blocklist_enabled

true means enabled

=head2 dht_enabled

 $boolean = $self->dht_enabled

true means allow dht in public torrents

=head2 encryption

 $string = $self->encryption

"required", "preferred", "tolerated"

=head2 download_dir

 $string = $self->download_dir

default path to download torrents

=head2 peer_limit_global

 $number = $self->peer_limit_global

maximum global number of peers

=head2 peer_limit_per_torrent

 $number = $self->peer_limit_per_torrent

maximum global number of peers

=head2 pex_enabled

 $boolean = $self->pex_enabled

true means allow pex in public torrents

=head2 peer_port

 $number = $self->peer_port

port number

=head2 peer_port_random_on_start

 $boolean = $self->peer_port_random_on_start

true means pick a random peer port on launch

=head2 port_forwarding_enabled

 $boolean = $self->port_forwarding_enabled

true means enabled

=head2 seedRatioLimit

 $double = $self->seedRatioLimit

the default seed ratio for torrents to use

=head2 seedRatioLimited

 $boolean = $self->seedRatioLimited

true if seedRatioLimit is honored by default

=head2 speed_limit_down

 $number = $self->speed_limit_down

max global download speed (in K/s)

=head2 speed_limit_down_enabled

 $boolean = $self->speed_limit_down_enabled

true means enabled

=head2 speed_limit_up

 $number = $self->speed_limit_up

max global upload speed (in K/s)

=head2 speed_limit_up_enabled

 $boolean = $self->speed_limit_up_enabled

true means enabled

=cut

BEGIN {
    my %both = qw/
        alt-speed-down             Num
        alt-speed-enabled          Bool
        alt-speed-time-begin       Num
        alt-speed-time-enabled     Bool
        alt-speed-time-end         Num
        alt-speed-time-day         Num
        alt-speed-up               Num
        blocklist-enabled          Bool
        dht-enabled                Bool
        encryption                 Str
        download-dir               Str
        peer-limit-global          Num
        peer-limit-per-torrent     Num
        pex-enabled                Bool
        peer-port                  Num
        peer-port-random-on-start  Bool
        port-forwarding-enabled    Bool
        seedRatioLimit             Num
        seedRatioLimited           Bool
        speed-limit-down           Num
        speed-limit-down-enabled   Bool
        speed-limit-up             Num
        speed-limit-up-enabled     Bool
    /;

    for my $camel (keys %both) {
        (my $name = $camel) =~ s/-/_/g;
        has $name => (
            is => 'rw',
            isa => "Maybe[$both{$camel}]",
            trigger => sub {
                return if($_[0]->lazy_write);
                $_[0]->client->rpc('session-set' => $camel => $_[1]);
            },
        );
    }

    __PACKAGE__->meta->add_method(read_all => sub {
        my $self = shift;
        my $lazy = $self->lazy_write;
        my $data;

        $data = $self->client->rpc('session-get') or return;

        $self->lazy_write(1);

        for my $camel (keys %both) {
            (my $name = $camel) =~ s/-/_/g;
            my $value = $data->{$camel};

            $value = 1 if($value eq 'true');
            $value = 0 if($value eq 'false');

            $self->$name($value);
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
