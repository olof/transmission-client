#!perl

use strict;
use warnings;
use lib qw(lib);
use Transmission::Client;
use Test::More;

plan skip_all => "REAL_TEST is not set" unless($ENV{'REAL_TEST'});
plan tests => 13;

my $obj = Transmission::Client->new;

is($obj->url, 'http://localhost:9091/transmission/rpc', '->url');
isa_ok($obj->session, 'Transmission::Session', '->session');
isa_ok($obj->stats, 'Transmission::Stats', '->stats');
ok($obj->torrents, '->torrents');
like($obj->version, qr{^1.7}, '->version');

ok(!$obj->add, "Could not add") or diag($obj->error);
ok(!$obj->remove, "Could not remove") or diag($obj->error);
ok(!$obj->start, "Could not start") or diag($obj->error);
ok(!$obj->stop, "Could not stop") or diag($obj->error);
ok(!$obj->verify, "Could not verify") or diag($obj->error);

is(int(@_ = $obj->read_torrents(eager_read => 1)), 3, "->read_torrents eagerly");
is(int(@_ = $obj->read_torrents(ids => 1)), 1, "->read_torrents with ids");

# at the end...
ok($obj->read_all, "data is refreshed");

#print $obj->dump;
