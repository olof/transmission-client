#!perl

use strict;
use warnings;
use lib qw(lib);
use Transmission::Client;
use Test::More tests => 8;

my $obj = Transmission::Client->new;
my $connected;

ok($obj, "Created transmission object");

$connected = $obj->version; # check for connection

_ok(scalar($obj->torrents), "->torrents") or diag($obj->error);
_ok(scalar($obj->stats), "->stats") or diag($obj->error);

ok(!$obj->add, "Could not add") or diag($obj->error);
ok(!$obj->remove, "Could not remove") or diag($obj->error);
ok(!$obj->start, "Could not start") or diag($obj->error);
ok(!$obj->stop, "Could not stop") or diag($obj->error);
ok(!$obj->verify, "Could not verify") or diag($obj->error);

sub _ok {
    my $value = shift;
    my $msg = shift;

    return $connected ? ok($value, $msg) : ok(!$value, $msg);
}
