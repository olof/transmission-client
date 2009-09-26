#!perl

use strict;
use warnings;
use lib qw(lib);
use Transmission::Client;
use Transmission::Torrent;
use Test::More tests => 3;

my $obj = Transmission::Torrent->new(
              client => Transmission::Client->new,
              id => 1,
          );

ok($obj->name, "->name is ok");
ok($obj->refresh_all, "data is refreshed");
ok($obj->total_size, "total_size is set");
ok($obj->files, "files is set");
ok($obj->files->[0]->name, "file data is set");

