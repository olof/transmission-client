package Transmission::Client;

=head1 NAME

Transmission::Client - Interface to Transmission

=head1 VERSION

0.01

=head1 DESCRIPTION

The documentation is half copy/paste from the Transmission RPC spec:
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

This module differs from L<P2P::Transmission> in (at least) two ways:
This one use L<Moose> and it won't die or confess, which is especially
annoying in the constructor.

=head1 SYNOPSIS

 use Transmission::Client;

 my $client = Transmission::Client->new;
 my $torrent_id = 2;
 my $data = base64_encoded_data();

 $client->add(metainfo => $data) or confess $client->error;
 $client->remove($torrent_id) or confess $client->error;

 for my $torrent (@{ $client->torrents }) {
    print $torrent->name, "\n";
    for my $file (@{ $torrent->files }) {
        print "> ", $file->name, "\n";
    }
 }

 print $client->session->download_dir, "\n";

=head1 SEE ALSO

L<Transmission::AttributeRole>

=cut

use Moose;
use DateTime;
use DateTime::Duration;
use JSON;
use LWP::UserAgent;
use MIME::Base64;
use Transmission::Torrent;
use Transmission::Session;

our $VERSION = '0.01';

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 url

 $str = $self->url;

Returns an URL to where the Transmission rpc api is.
Default value is "http://localhost:9091/transmission/rpc";

=cut

has url => (
    is => 'ro',
    isa => 'Str',
    default => 'http://localhost:9091/transmission/rpc',
);

=head2 error

 $str = $self->error;
 
Returns the last error known to the object. All methods can return
empty list in addtion to what spesified. Check this attribute if so happens.

=cut

has error => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

=head2 username

 $str = $self->username;

Used to authenticate against Transmission.

=cut

has username => (
    is => 'ro',
    isa => 'Str',
);

=head2 password

 $str = $self->password;

Used to authenticate against Transmission.

=cut

has password => (
    is => 'ro',
    isa => 'Str',
);

=head2 timeout

 $int = $self->timeout;

Number of seconds to wait for RPC response.

=cut

has _ua => (
    is => 'rw',
    isa => 'LWP::UserAgent',
    lazy => 1,
    handles => [qw/timeout/],
    default => sub {
        my $self = shift;
        my $ua = LWP::UserAgent->new;
        my @url = split m"/+:", $self->url;

        if($self->username and $self->password) {
            $ua->credentials(
                $url[1],
                "Transmission RPC Server",
                $self->username,
                $self->password,
            );
        }

        return $ua;
    },
);

=head2 session

 $session_obj = $self->session;
 $stats_obj = $self->stats;

Returns an instance of L<Transmission::Session>.
C<stats()> is a proxy method on L</session>.

=cut

has session => (
    is => 'ro',
    lazy => 1,
    handles => [qw/stats/],
    default => sub {
        Transmission::Session->new( client => $_[0] );
    },
);

=head2 torrents

 $array_ref = $self->torrents;
 $self->clear_torrents;

Returns an array-ref of L<Transmission::Torrent> objects. Default value
is a full list of all known torrents, with as little data as possible read
from Transmission. This means that each request on a attribute on an object
will require a new request to Transmission. See L</read_torrents> for more
information.

=cut

has torrents => (
    is => 'rw',
    lazy => 1,
    clearer => "clear_torrents",
    builder => "read_torrents",
);

=head2 version

 $str = $self->version;

Get Transmission version.

=cut

has version => (
    is => 'ro',
    lazy_build => 1,
    isa => 'Str',
);

around version => sub {
    my $next = shift;
    my $self = shift;
    my $version = $self->$next(@_);

    $self->clear_version unless($version);

    return $version || undef;
};

sub _build_version {
    my $self = shift;

    if(my $data = $self->rpc('session-get')) {
        return $data->{'version'} || q();
    }

    return q();
}

has _session_id => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

=head1 METHODS

=head2 add

 $bool = $self->add(%args);

 key              | value type & description
 -----------------+-------------------------------------------------
 download_dir     | string    path to download the torrent to
 filename         | string    filename or URL of the .torrent file
 metainfo         | string    torrent content
 paused           | boolean   if true, don't start the torrent
 peer_limit       | number    maximum number of peers

Either "filename" or "metainfo" MUST be included. All other arguments are
optional.

See "3.4 Adding a torrent" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

=cut

sub add {
    my $self = shift;
    my %args = @_;

    if($args{'filename'} and $args{'metainfo'}) {
        $self->error("Filename and metainfo argument crash");
        return;
    }
    elsif($args{'filename'}) {
        return $self->rpc('torrent-add', %args);
    }
    elsif($args{'metainfo'}) {
        $args{'metainfo'} = encode_base64($args{'metainfo'});
        return $self->rpc('torrent-add', %args);
    }
    else {
        $self->error("Need either filename or metainfo argument");
        return;
    }
}

=head2 remove

 $bool = $self->remove(%args);

 key                | value type & description
 -------------------+-------------------------------------------------
 ids                | array    torrent list, as described in 3.1
 delete_local_data  | boolean  delete local data. (default: false)

C<ids> can also be the string "all". C<ids> is required.

See "3.4 Removing a torrent" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

=cut

sub remove {
    my $self = shift;
    my %args = @_;

    if(!defined $args{'ids'}) {
        $self->error("ids argument is required");
        return;
    }
    elsif($args{'ids'} eq 'all') {
        delete $args{'ids'};
        return $self->rpc('torrent-remove' => %args);
    }
    else {
        $args{'ids'} = [$args{'ids'}] unless(ref $args{'ids'} eq 'ARRAY');
        return $self->rpc('torrent-remove', %args);
    }
}

=head2 move

 $bool = $self->move(%args);


 string      | value type & description
 ------------+-------------------------------------------------
 ids         | array      torrent list, as described in 3.1
 location    | string     the new torrent location
 move        | boolean    if true, move from previous location.
             |            otherwise, search "location" for files

C<ids> can also be the string "all". C<ids> and C<location> is required.

See "3.5 moving a torrent" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

=cut

sub move {
    my $self = shift;
    my %args = @_;

    if(!defined $args{'ids'}) {
        $self->error("ids argument is required");
        return;
    }
    if(!defined $args{'location'}) {
        $self->error("ids argument is required");
        return;
    }

    if($args{'ids'} eq 'all') {
        delete $args{'ids'};
        return $self->rpc('torrent-set-location' => %args);
    }
    else {
        $args{'ids'} = [$args{'ids'}] unless(ref $args{'ids'} eq 'ARRAY');
        return $self->rpc('torrent-set-location', %args);
    }
}

=head2 start

 $bool = $self->start($ids);

Will start one or more torrents.
C<$ids> can be a single int, an array of ints or the string "all".

=head2 stop

 $bool = $self->stop($ids);

Will stop one or more torrents.
C<$ids> can be a single int, an array of ints or the string "all".

=head2 verify

 $bool = $self->stop($ids);

Will verify one or more torrents.
C<$ids> can be a single int, an array of ints or the string "all".

=cut

sub start {
    return shift->_do_ids_action('torrent-start' => @_);
}

sub stop {
    return shift->_do_ids_action('torrent-stop' => @_);
}

sub verify {
    return shift->_do_ids_action('torrent-verify' => @_);
}

sub _do_ids_action {
    my $self   = shift;
    my $method = shift;
    my $ids;

    # hack to provide an uniform api
    if(@_ % 2 == 0) {
        my %args = @_;
        $ids = $args{'ids'};
    }
    else {
        $ids = $_[0];
    }

    if(!defined $ids) {
        $self->error("ids argument is required");
        return;
    }
    elsif($ids eq 'all') {
        return $self->rpc($method);
    }
    else {
        $ids = [$ids] unless(ref $ids eq 'ARRAY');
        return $self->rpc($method, ids => $ids);
    }
}

=head2 read_torrents

 @list = $self->read_torrents(%args);
 $array_ref = $self->read_torrents(%args);

 key         | value type & description
 ------------+-------------------------------------------------
 ids         | array      torrent list, as described in 3.1
             |            this is optional
 eager_read  | will create objects with as much data as possible.

=over 4

=item List context

Returns a list of L<Transmission::Torrent> objects and sets the L</torrents>
attribute.

=item Scalar context

Returns an array-ref of L<Transmission::Torrent>.

=back

=cut

sub read_torrents {
    my $self = shift;
    my %args = @_;
    my $list;

    if($args{'eager_read'}) {
        $args{'fields'} = [
            keys %Transmission::Torrent::READ,
            keys %Transmission::Torrent::BOTH,
        ];
    }
    else {
        $args{'fields'} = [qw/id/];
    }

    if(my $data = $self->rpc('torrent-get' => %args)) {
        $list = $data->{'torrents'};
    }
    else {
        $list = [];
    }

    for my $torrent (@$list) {
        $torrent = Transmission::Torrent->new(
                        client => $self,
                        id => $torrent->{'id'},
                        %$torrent,
                   );
    }

    if(wantarray) {
        $self->torrents($list);
        return @$list;
    }
    else {
        return $list;
    }
}

=head2 rpc

 $any = $self->rpc($method, %args);

Communicate with backend. This methods is meant for internal use.

=cut

sub rpc {
    my $self = shift;
    my $method = shift or return;
    my %args = @_;
    my $nested = delete $args{'_nested'}; # internal flag
    my $session_header_name = 'X-Transmission-Session-Id';
    my($tag, $res, $post);

    $self->_translateCamel(\%args);

    if(ref $args{'ids'} eq 'ARRAY') {
        $_ += 0 for(@{ $args{'ids'} });
    }

    $tag  = int rand 2*16 - 1;
    $post = to_json({
                method    => $method,
                tag       => $tag,
                arguments => \%args,
            });

    $self->_ua->default_header($session_header_name => $self->_session_id);

    $res = $self->_ua->post($self->url, Content => $post);

    unless($res->is_success) {
        if($res->code == 409 and !$nested) {
            $self->_session_id($res->header($session_header_name));
            return $self->rpc($method => %args, _nested => 1);
        }
        $self->error($res->status_line);
        return;
    }

    $res = from_json($res->content);

    unless($res->{'tag'} == $tag) {
        $self->error("Tag mismatch");
        return;
    }
    unless($res->{'result'} eq 'success') {
        $self->error($res->{'result'});
        return;
    }

    return $res->{'arguments'};
}

=head2 read_all

 1 == $self->read_all;

This method will try to populate ALL torrent, session and stats information,
using three requests.

=cut

sub read_all {
    my $self = shift;

    $self->session->read_all;
    $self->stats->read_all;
    $self->read_torrents(eager_read => 1);

    return 1;
}

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen

=cut

1;
