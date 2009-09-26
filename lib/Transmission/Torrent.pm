package Transmission::Torrent;

=head1 NAME

Transmission::Torrent

=cut

use Moose;

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

=head2 client

 $obj = $self->client;

Returns a L<Transmission::Client> object.

=cut

has client => (
    is => 'ro',
    isa => 'Object',
    required => 1,
);

{
    my %set = qw/
        files-wanted          ArrayRef
        files-unwanted        ArrayRef
        location              Str
        peer-limit            Num
        priority-high         ArrayRef
        priority-low          ArrayRef
        priority-normal       ArrayRef
    /;
    my %both = qw/
        bandwidthPriority     Num
        downloadLimit         Num
        downloadLimited       Bool
        honorsSessionLimits   Bool
        seedRatioLimit        Num
        seedRatioMode         Num
        uploadLimit           Num
        uploadLimited         Bool
    /;
    my %read = qw/
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
        files                       ArrayRef
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
        #fileStats                   ArrayRef
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
                $_[0]->client->rpc('torrent-set' =>
                    ids => [ $_[0]->id ], $camel => $_[1],
                );
            },
        );
    }

    for my $camel (keys %both) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'rw',
            isa => "Maybe[$both{$camel}]",
            lazy => 1,
            trigger => sub {
                $_[0]->client->rpc('torrent-set' =>
                    ids => [ $_[0]->id ], $camel => $_[1],
                );
            },
            default => sub {
                my $res = $_[0]->client->rpc('torrent-get' =>
                                ids => [ $_[0]->id ],
                                fields => [ $camel ],
                            ) or return;

                return $res->{'torrents'}[0]{$camel};
            },
        );
    }

    for my $camel (keys %read) {
        (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
        has $name => (
            is => 'ro',
            isa => "Maybe[$read{$camel}]",
            writer => "_set_$name",
            lazy => 1,
            default => sub {
                my $res = $_[0]->client->rpc('torrent-get' =>
                                ids => [ $_[0]->id ],
                                fields => [ $camel ],
                            ) or return;

                return $res->{'torrents'}[0]{$camel};
            },
        );
    }

    __PACKAGE__->meta->add_method(refresh_all => sub {
        my $self = shift;
        my($res, $torrent);

        $res = $self->client->rpc('torrent-get' =>
                   ids => [ $self->id ],
                   fields => [ keys %both, keys %read ],
               ) or return;

        $torrent = $res->{'torrents'}[0] or return;

        for my $camel (keys %$torrent) {
            (my $name = $camel) =~ s/([A-Z]+)/{ "_" .lc($1) }/ge;
            my $value = $torrent->{$camel};
            my $writer;

            if($both{$camel}) {
                $writer = $name;
                $value = "$value" unless($both{$camel} eq 'ArrayRef');
            }
            elsif($read{$camel}) {
                $writer = "_set_$name";
                $value = "$value" unless($read{$camel} eq 'ArrayRef');
            }
            else {
                next;
            }

            $value = 1 if($value eq 'true');
            $value = 0 if($value eq 'false');

            $self->$writer($value);
        }

        return 1;
    });
}

=head1 METHODS

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
