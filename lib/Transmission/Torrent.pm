package Transmission::Torrent;

=head1 NAME

Transmission::Torrent

=head1 DESCRIPTION

See "3.2 Torrent Mutators" and "3.3 Torrent accessors" from
L<http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt>

=head2 SEE ALSO

L<Transmission::AttributeRole>

=cut

use Moose;
use Transmission::Torrent::File;

our(%READ, %BOTH);

with 'Transmission::AttributeRole';

=head1 ATTRIBUTES

=head2 id

 $id = $self->id;

Returns the id that identifies this torrent in transmission.

=cut

has id => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

=head2 bandwidth_priority

 $self->bandwidth_priority($num);

This torrent's bandwidth.

=head2 download_limit

 $self->download_limit($num);

Maximum download speed (in K/s).

=head2 download_limited

 $self->download_limited($bool);

True if "downloadLimit" is honored.

=head2 honors_session_limits

 $self->honors_session_limits($bool);

True if session upload limits are honored.

=head2 location

 $self->location($str);

New location of the torrent's content

=head2 peer_limit

 $self->peer_limit($num);

Maximum number of peers

=head2 seed_ratio_limit

 $self->seed_ratio_limit($num);

Session seeding ratio.

=head2 seed_ratio_mode

 $self->seed_ratio_mode($num);

Which ratio to use. See tr_ratiolimit.

=head2 upload_limit

 $self->upload_limit($num);

Maximum upload speed (in K/s)

=head2 upload_limited

 $self->upload_limited($bool);

True if "upload_limit" is honored

=head2 activity_date

 $num = $self->activity_date;

=head2 added_date

 $num = $self->added_date;

=head2 bandwidth_priority

 $num = $self->bandwidth_priority;

=head2 comment

 $str = $self->comment;

=head2 corrupt_ever

 $num = $self->corrupt_ever;

=head2 creator

 $str = $self->creator;

=head2 date_created

 $num = $self->date_created;

=head2 desired_available

 $num = $self->desired_available;

=head2 done_date

 $num = $self->done_date;

=head2 download_dir

 $str = $self->download_dir;

=head2 downloaded_ever

 $num = $self->downloaded_ever;

=head2 downloaders

 $num = $self->downloaders;

=head2 download_limit

 $num = $self->download_limit;

=head2 download_limited

 $bool = $self->download_limited;

=head2 error

 $num = $self->error;

=head2 error_str

 $str = $self->error_string;

=head2 eta

 $num = $self->eta;

=head2 hash_str

 $str = $self->hash_string;

=head2 have_unchecked

 $num = $self->have_unchecked;

=head2 have_valid

 $num = $self->have_valid;

=head2 honors_session_limits

 $bool = $self->honors_session_limits;

=head2 id

 $num = $self->id;

=head2 is_private

 $bool = $self->is_private;

=head2 leechers

 $num = $self->leechers;

=head2 left_until_done

 $num = $self->left_until_done;

=head2 manual_announce_time

 $num = $self->manual_announce_time;

=head2 max_connected_peers

 $num = $self->max_connected_peers;

=head2 name

 $str = $self->name;

=head2 peer

 $num = $self->peer;

=head2 peers_connected

 $num = $self->peers_connected;

=head2 peers_getting_from_us

 $num = $self->peers_getting_from_us;

=head2 peers_known

 $num = $self->peers_known;

=head2 peers_sending_to_us

 $num = $self->peers_sending_to_us;

=head2 percent_done

 $num = $self->percent_done;

=head2 pieces

 $str = $self->pieces;

=head2 piece_count

 $num = $self->piece_count;

=head2 piece_size

 $num = $self->piece_size;

=head2 rate_download

 $num = $self->rate_download;

=head2 rate_upload

 $num = $self->rate_upload;

=head2 recheck_progress

 $num = $self->recheck_progress;

=head2 seeders

 $num = $self->seeders;

=head2 seed_ratio_limit

 $num = $self->seed_ratio_limit;

=head2 seed_ratio_mode

 $num = $self->seed_ratio_mode;

=head2 size_when_done

 $num = $self->size_when_done;

=head2 start_date

 $num = $self->start_date;

=head2 status

 $num = $self->status;

=head2 swarm_speed

 $num = $self->swarm_speed;

=head2 times_completed

 $num = $self->times_completed;

=head2 total_size

 $num = $self->total_size;

=head2 torrent_file

 $str = $self->torrent_file;

=head2 uploaded_ever

 $num = $self->uploaded_ever;

=head2 upload_limit

 $num = $self->upload_limit;

=head2 upload_limited

 $bool = $self->upload_limited;

=head2 upload_ratio

 $num = $self->upload_ratio;

=head2 webseeds_sending_to_us

 $num = $self->webseeds_sending_to_us;

=cut

BEGIN {
    my %set = qw/
        files-wanted          ArrayRef
        files-unwanted        ArrayRef
        location              Str
        peer-limit            Num
        priority-high         ArrayRef
        priority-low          ArrayRef
        priority-normal       ArrayRef
    /;
    %BOTH = qw/
        bandwidthPriority     Num
        downloadLimit         Num
        downloadLimited       Bool
        honorsSessionLimits   Bool
        seedRatioLimit        Num
        seedRatioMode         Num
        uploadLimit           Num
        uploadLimited         Bool
    /;
    %READ = qw/
        activityDate                Num
        addedDate                   Num
        comment                     Str
        corruptEver                 Num
        creator                     Str
        dateCreated                 Num
        desiredAvailable            Num
        doneDate                    Num
        downloadDir                 Str
        downloadedEver              Num
        downloaders                 Num
        error                       Num
        errorString                 Str
        eta                         Num
        hashString                  Str
        haveUnchecked               Num
        haveValid                   Num
        isPrivate                   Bool
        leechers                    Num
        leftUntilDone               Num
        manualAnnounceTime          Num
        maxConnectedPeers           Num
        name                        Str
        peersConnected              Num
        peersGettingFromUs          Num
        peersKnown                  Num
        peersSendingToUs            Num
        percentDone                 Num
        pieceCount                  Num
        pieceSize                   Num
        rateDownload                Num
        rateUpload                  Num
        recheckProgress             Num
        seeders                     Num
        sizeWhenDone                Num
        startDate                   Num
        status                      Num
        swarmSpeed                  Num
        timesCompleted              Num
        totalSize                   Num
        torrentFile                 Str
        uploadedEver                Num
        uploadRatio                 Num
        webseedsSendingToUs         Num
    /;
        #peers                       ArrayRef
        #peersFrom                   Object
        #pieces                      Str
        #priorities                  ArrayRef
        #trackers                    ArrayRef
        #trackerStats                ArrayRef
        #wanted                      ArrayRef
        #webseeds                    ArrayRef

    for my $camel (keys %set) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'rw',
            isa => $set{$camel},
            trigger => sub {
                return if($_[0]->lazy_write);
                $_[0]->client->rpc('torrent-set' =>
                    ids => [ $_[0]->id ], $camel => $_[1],
                );
            },
        );
    }

    for my $camel (keys %BOTH) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'rw',
            isa => "Maybe[$BOTH{$camel}]",
            lazy => 1,
            trigger => sub {
                return if($_[0]->lazy_write);
                $_[0]->client->rpc('torrent-set' =>
                    ids => [ $_[0]->id ], $camel => $_[1],
                );
            },
            default => sub {
                my $data = $_[0]->client->rpc('torrent-get' =>
                               ids => [ $_[0]->id ],
                               fields => [ $camel ],
                           ) or return;

                return $data->{'torrents'}[0]{$camel};
            },
        );
    }

    for my $camel (keys %READ) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'ro',
            isa => "Maybe[$READ{$camel}]",
            writer => "_set_$name",
            lazy => 1,
            default => sub {
                my $data = $_[0]->client->rpc('torrent-get' =>
                               ids => [ $_[0]->id ],
                               fields => [ $camel ],
                           ) or return;

                return $data->{'torrents'}[0]{$camel};
            },
        );
    }

    __PACKAGE__->meta->add_method(read_all => sub {
        my $self = shift;
        my $lazy = $self->lazy_write;
        my $data;

        $data = $self->client->rpc('torrent-get' =>
                    ids => [ $self->id ],
                    fields => [ keys %BOTH, keys %READ ],
                ) or return;

        $data = $data->{'torrents'}[0] or return;

        $self->lazy_write(1);

        for my $camel (keys %$data) {
            (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
            my $value = $data->{$camel};
            my $writer;

            if($BOTH{$camel}) {
                $writer = $name;
                $value = "$value" unless($BOTH{$camel} eq 'ArrayRef');
            }
            elsif($READ{$camel}) {
                $writer = "_set_$name";
                $value = "$value" unless($READ{$camel} eq 'ArrayRef');
            }
            else {
                next;
            }

            $value = 1 if($value eq 'true');
            $value = 0 if($value eq 'false');

            $self->$writer($value);
        }

        $self->lazy_write($lazy);

        return 1;
    });
}

=head2 files

 $array_ref = $self->files;

Returns an array of L<Transmission::Torrent::File>s.

=cut

has files => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_files {
    my $self = shift;
    my $files = [];
    my $stats = [];
    my $data;

    $data = $self->client->rpc('torrent-get' =>
                ids => [ $self->id ],
                fields => [ qw/ files fileStats / ],
            ) or return [];

    $files = $data->{'torrents'}[0]{'files'};
    $stats = $data->{'torrents'}[0]{'fileStats'};

    while(@$stats) {
        my $stats = shift @$stats or last;
        my $file = shift @$files;

        push @$files, Transmission::Torrent::File->new(%$stats, %$file);
    }

    return $files;
}

=head1 METHODS

=head2 read_all

 $bool = $self->read_all;

This method will refresh all attributes in one RPC request, while calling one
and one attribute, results in one-and-one request.

=head2 write_all

 $bool = $self->write_all;

This method will write all attributes in one RPC request.

=head2 start

L<Transmission::Client::start()>.

=head2 stop

L<Transmission::Client::stop()>.

=head2 verify

L<Transmission::Client::verify()>.

=cut

{
    for my $name (qw/ start stop verify /) {
        __PACKAGE__->meta->add_method($name => sub {
            $_[0]->client->$name(ids => $_[0]->id);
        });
    }
}

=head1 LICENSE

=head1 AUTHOR

See L<Transmission::Client>.

=cut

1;
