#!perl

use strict;
use warnings;
use lib qw(lib);
use Transmission::Client;
use Test::More tests => 1;

my $obj = Transmission::Client->new;

ok($obj, "Created transmission object");
