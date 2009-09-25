package Transmission::Client;

=head1 NAME

Transmission::Client - Interface to Transmission

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

our %FIELDS_TEMPLATE;

=head1 VARIABLES

=head2 %FIELDS_TEMPLATE

A hash containing C<template_name => sub{}> keys. the C<sub{}> returns
a list of keys.

Predefined templates are: all, date, download, error, files, upload.

=cut

%FIELDS_TEMPLATE = (
    date => sub { grep { /date|eta/i } $FIELDS_TEMPLATE{'all'}->() },
    download => sub { grep { /download/i } $FIELDS_TEMPLATE{'all'}->() },
    error => sub { grep { /error/i } $FIELDS_TEMPLATE{'all'}->() },
    files => sub { grep { /files|hash/i } $FIELDS_TEMPLATE{'all'}->() },
    upload => sub { grep { /upload/i } $FIELDS_TEMPLATE{'all'}->() },
    default => sub { qw/id name comment error errorString eta/ },
    all => sub { qw/
        activityDate addedDate announceResponse announceURL
        comment corruptEver creator dateCreated
        desiredAvailable doneDate downloadDir downloadedEver
        downloaders downloadLimitMode downloadLimit error
        errorString eta files hashString
        haveUnchecked haveValid id isPrivate
        lastAnnounceTime lastScrapeTime leechers leftUntilDone
        manualAnnounceTime maxConnectedPeers name nextAnnounceTime
        nextScrapeTime peers peersConnected peersFrom
        peersGettingFromUs peersKnown peersSendingToUs pieceCount
        pieceSize priorities rateDownload rateUpload
        recheckProgress scrapeResponse scrapeURL seeders
        sizeWhenDone startDate status swarmSpeed
        timesCompleted trackers totalSize uploadedEver
        uploadLimitMode uploadLimit uploadRatio wanted
        webseeds webseedsSendingToUs
    / },
);

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

    if(my $res = $self->rpc('session-get')) {
        return $res->{'version'} || q();
    }

    return q();
}

=head1 METHODS

=head2 add

 $bool = $self->add(%args);

 key              | value type & description
 -----------------+-------------------------------------------------
 download_dir     | string      path to download the torrent to
 filename         | string      filename or URL of the .torrent file
 metainfo         | string      .torrent content
 paused           | 'boolean'   if true, don't start the torrent
 peer_limit       | number      maximum number of peers

Either "filename" or "metainfo" MUST be included. All other arguments are
optional.

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
 ids                | array      torrent list, as described in 3.1
 delete_local_data  | 'boolean'  delete local data. (default: false)

C<ids> can also be the string "all". C<ids> is required.

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
        $self->error("ids are missing in argument list");
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
 @array = $self->torrents(%args);

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

    if(my $template = delete $args{'template'}) {
        $args{'fields'} = [ $FIELDS_TEMPLATE{$template}->() ];
    }
    if(!$args{'fields'}) {
        $args{'fields'} = [ $FIELDS_TEMPLATE{'default'}->() ];
    }

    if(my $res = $self->rpc('torrent-get' => %args)) {
        $list = $res->{'torrents'};
    }
    else {
        return;
    }

    @$list = sort { 
                    $a->{'status'} <=> $b->{'status'}
                 || $a->{'name'}   cmp $b->{'name'}
             } @$list;

    for my $torrent (@$list) {
        $self->_translateCamel($torrent);
    }

    return wantarray ? @$list : $list;
}

sub _translateCamel {
    my $self = shift;
    my $h    = shift;

    for(keys %$h) {
        (my $key = $_) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;

        if(my $tr = $self->can("_translate_$key")) {
            $h->{$key} = $tr->($h->{$_});
        }
        else {
            $h->{$key} = delete $h->{$_};
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

=head2 encryption

 ?? = $self->encryption;

=head2 download_dir

 $str = $self->download_dir;

Returns the path to where transmission download files.

=head2 peer_limit

 $int = $self->peer_limit;

=head2 pex_allowed

 ?? = $self->pex_allowed;

=head2 port

 $int = $self->port;

=head2 port_forwarding_enabled

 $bool = $self->port_forwarding_enabled;

=head2 speed_limit_down

 $int = $self->speed_limit_down;

=head2 speed_limit_down_enabled

 $bool = $self->speed_limit_down_enabled;

=head2 speed_limit_up

 $int = $self->speed_limit_up;

=head2 speed_limit_up_enabled

 $bool = $self->speed_limit_up_enabled;

=cut

{
    my $meta = __PACKAGE__->meta;
    my @session = qw/encryption download_dir peer_limit pex_allowed
                    port port_forwarding_enabled
                    speed_limit_down speed_limit_down_enabled
                    speed_limit_up speed_limit_up_enabled/;
    my @stats = qw/active_torrent_count download_speed
                    paused_torrent_count torrent_count upload_speed/;

    no strict 'refs';

    for my $sub (@session) {
        (my $key = $sub) =~ tr/_/-/;

        $meta->add_method($sub => sub {
            my $self = shift;
            my $val  = shift;

            if(defined $val) {
                return $self->rpc('session-set', $key => $val);
            }
            elsif(my $res = $self->rpc('session-get')) {
                return $res->{$key};
            }

            return;
        });
    }

    for my $sub (@stats) {
        (my $key = $sub) =~ s/_(\w)/{uc $1}/ge;

        $meta->add_method($sub => sub {
            my $res = shift->rpc('session-stats');
            return $res ? $res->{'session-stats'}{$key} : undef;
        });
    }
}

=head2 stats

 ?? = $self->stats;

=cut

sub stats {
    my $stats = shift->rpc('session-stats');

    return $stats->{'session-stats'} if(ref $stats eq 'HASH');
    return;
}

=head2 rpc

 $any = $self->rpc($method, %args);

Communicate with backend. This methods is meant for internal use.

=cut

sub rpc {
    my $self = shift;
    my $method = shift or return {};
    my %args = _translate_keys(@_);
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

    $res = $self->_ua->post($self->url, Content => $post);

    unless($res->is_success) {
        $self->error($res->status_line);
        return;
    }

    $res = from_json($res->content);

    unless($res->{'tag'} == $tag) {
        $self->error("Tag mismatch");
        return;
    }

    warn $res->{'result'}; #??

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
