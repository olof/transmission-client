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

_ok(scalar($obj->torrents), "->torrents");
_ok(scalar($obj->stats), "->stats");

ok(!$obj->add, "Could not add");
ok(!$obj->remove, "Could not remove");
ok(!$obj->start, "Could not start");
ok(!$obj->stop, "Could not stop");
ok(!$obj->verify, "Could not verify");

sub _ok {
    my $value = shift;
    my $msg = shift;

    return $connected ? ok($value, $msg) : ok(!$value, $msg);
}
