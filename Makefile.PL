use inc::Module::Install;

name     q(Transmission-Client);
all_from q(lib/Transmission/Client.pm);

# copy/paste from JSON-Any/Makefile.PL
sub has_json () {
    our @order = qw(XS JSON DWIW);
    foreach my $testmod (@order) {
        $testmod = "JSON::$testmod" unless $testmod eq "JSON";
        eval "require $testmod";
        return 1 unless $@;
    }
    return 0;
}

unless (has_json) {
    requires 'JSON' => '2.02';
}
else {
    feature 'JSON', -default => 0, 'JSON'   => '2.02';
}

requires q(DateTime) => 0.50;
requires q(JSON::Any) => 1.20;
requires q(LWP::UserAgent) => 5.8;
requires q(MIME::Base64) => 3.00;
requires q(Moose) => 0.80;
requires q(MooseX::Types) => 0.20;
requires q(Sub::Exporter) => 0.95;
requires q(List::MoreUtils) => 0;

test_requires q(Test::More) => 0;

auto_install;
WriteAll;
