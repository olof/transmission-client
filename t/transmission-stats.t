use strict;
use warnings;

use Test::More tests => 1;

use Transmission::Stats;

%::test_stats = (
    activeTorrentCount => 1,
    downloadSpeed      => 2,
    pausedTorrentCount => 3,
    torrentCount       => 4,
);

{ 
    package Mock::Client;
    use Moose;
    sub rpc { \%::test_stats }
}

my $stats = Transmission::Stats->new( client => Mock::Client->new );

can_ok $stats, qw/ _tmp_store read_all /;

subtest 'read_all' => sub {
    $stats->read_all;

    for ( keys %::test_stats ) {
        my $method = Transmission::Stats->_camel2Normal($_);
        is $stats->$method => $::test_stats{$_};
    }
};
