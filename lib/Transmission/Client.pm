package Transmission::Client;

=head1 NAME

Transmission::Client - Interface to Transmission

=head1 VERSION

0.01

=head1 SYNOPSIS

 use Transmission::Client;

 my $client = Transmission::Client->new;

=head1 DESCRIPTION

The documentation is half copy/paste from the Transmission RPC spec:
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

This module differs from L<P2P::Transmission> in (at least) two ways:
This one use L<Moose> and it won't die or confess, which is especially
annoying in the constructor.

=cut

use Moose;
use DateTime;
use DateTime::Duration;
use JSON;
use LWP::UserAgent;
use MIME::Base64;
use Transmission::Torrent;

our $VERSION = '0.01';

=head1 ATTRIBUTES

=head2 url

 $str = $self->url;

Returns an URL to where the transmission rpc api is.

=cut

has url => (
    is => 'ro',
    isa => 'Str',
    default => 'http://localhost:9091/transmission/rpc',
);

=head2 session_id

 $str = $self->session_id;

Returns the session ID used in HTTP header, when comunicating with
transmission.

=cut

has session_id => (
    is => 'rw',
    isa => 'Str',
    default => '',
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

=head2 torrents

 $array_ref = $self->torrents(%args);

 key       | value type & description
 ----------+-------------------------------------------------
 ids       | array      torrent list, as described in 3.1
           |            this is optional
 fields    | array      described in 3.3 
           |            default field array is ["id"]
 template  | string     a template describing pre-defined fields
 
Returns a list of torrent data or empty list on failure.

=cut

sub torrents {
    my $self = shift;
    my %args = @_;
    my $list;

    $args{'fields'} ||= [
        keys %Transmission::Torrent::READ,
        keys %Transmission::Torrent::BOTH,
    ];

    if(my $data = $self->rpc('torrent-get' => %args)) {
        $list = $data->{'torrents'};
    }
    else {
        return;
    }

    for my $torrent (@$list) {
        $self->_translateCamel($torrent);
        local $torrent->{'parent'} = $self;
        $torrent = Transmission::Torrent->new(%$torrent);
    }

    return $list;
}

sub _translateCamel {
    my $self = shift;
    my $h    = shift;

    for(keys %$h) {
        (my $key = $_) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;

        if(my $tr = $self->can("_translate_$key")) {
            $h->{$key} = $tr->( delete $h->{$_} );
        }
        else {
            $h->{$key} = delete $h->{$_};
        }

        if(ref $h->{$key} eq 'HASH') {
            $self->_translateCamel($h->{$key});
        }
    }
}

sub _translate_status {
    return 'queued'      if($_[0] == 1);
    return 'checking'    if($_[0] == 2);
    return 'downloading' if($_[0] == 4);
    return 'seeding'     if($_[0] == 8);
    return 'stopped'     if($_[0] == 16);
    return $_[0];
}

=head2 stats

 $hash_ref = $self->stats;

Returns data from 'session-stats' RPC call. See chapter 4.2 in RPC spec.
Note: All keys are converted from "CamelCase" to "camel_case".

=cut

sub stats {
    my $self = shift;
    my $stats = $self->rpc('session-stats');

    $self->_translateCamel($stats);

    return $stats if(ref $stats eq 'HASH');
    return;
}

=head2 rpc

 $any = $self->rpc($method, %args);

Communicate with backend. This methods is meant for internal use.

=cut

sub rpc {
    my $self = shift;
    my $method = shift or return;
    my %args = _translate_keys(@_);
    my $nested = delete $args{'_nested'}; # internal flag
    my $session_header_name = 'X-Transmission-Session-Id';
    my($tag, $res, $post);

    if(ref $args{'ids'} eq 'ARRAY') {
        $_ += 0 for(@{ $args{'ids'} });
    }

    $tag  = int rand 2*16 - 1;
    $post = to_json({
                method    => $method,
                tag       => $tag,
                arguments => \%args,
            });

    $self->_ua->default_header($session_header_name => $self->session_id);

    $res = $self->_ua->post($self->url, Content => $post);

    unless($res->is_success) {
        if($res->code == 409 and !$nested) {
            $self->session_id($res->header($session_header_name));
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

sub _translate_keys {
    my %args = @_;

    for my $orig (keys %args) {
        my $new = $orig;
        $new =~ tr/_/-/;
        $args{$new} = delete $args{$orig};
    }

    return %args;
}

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Jan Henning Thorsen

=cut

1;
