package Rota::Persistence::GCS;

use strict;
use warnings;

use JSON::PP;
use DateTime;
use HTTP::Tiny;
use URI::Escape qw(uri_escape_utf8);

use Rota::Google::Token;

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        bucket  => $args{bucket}  || $ENV{PERSISTENCE_GCS_BUCKET},
        object  => $args{object}  || $ENV{PERSISTENCE_GCS_OBJECT} || 'rota.json',
        ua_opts => $args{ua_opts} || {},
    }, $class;

    die "GCS bucket is required for GCS persistence" unless $self->{bucket};

    return $self;
}

sub _token {
    my $token = eval { Rota::Google::Token::get_gcloud_token() };
    if ($@) {
        die "Unable to get GCP access token: $@";
    }
    die "Unable to get GCP access token" unless $token;
    return $token;
}

sub _http {
    my ($self) = @_;
    return HTTP::Tiny->new( %{ $self->{ua_opts} } );
}

sub _object_escaped {
    my ($self) = @_;

    # GCS expects object name URL-encoded when used in path or query
    return uri_escape_utf8( $self->{object} );
}

sub read_rota {
    my ($self) = @_;

    my $token = $self->_token;
    my $ua    = $self->_http;

    my $obj = $self->_object_escaped;
    my $url = "https://storage.googleapis.com/storage/v1/b/" . uri_escape_utf8( $self->{bucket} ) . "/o/$obj?alt=media";

    my $res = $ua->get( $url, { headers => { Authorization => "Bearer $token" } } );

    return unless $res->{status} && $res->{status} == 200;

    my $data = eval { decode_json( $res->{content} ) };
    return unless $data && ref $data eq 'ARRAY';

    my @assignments = map {
        my $d = $_->{date};
        my ( $y, $m, $day ) = split /-/, $d;
        { date => DateTime->new( year => $y, month => $m, day => $day ), name => $_->{name} }
    } @$data;

    return \@assignments;
}

sub write_rota {
    my ( $self, $assignments ) = @_;

    my $token = $self->_token;
    my $ua    = $self->_http;

    my $data = [ map { { date => $_->{date}->ymd, name => $_->{name} } } @$assignments ];
    my $json = encode_json($data);

    my $bucket_esc = uri_escape_utf8( $self->{bucket} );
    my $obj        = $self->_object_escaped;
    my $url        = "https://storage.googleapis.com/upload/storage/v1/b/$bucket_esc/o?uploadType=media&name=$obj";

    my $res = $ua->post(
        $url,
        {   headers => {
                Authorization  => "Bearer $token",
                'Content-Type' => 'application/json',
            },
            content => $json,
        }
    );

    unless ( $res->{status} && ( $res->{status} == 200 || $res->{status} == 201 ) ) {
        die "GCS write failed: " . ( $res->{status} || '' ) . " - " . ( $res->{content} || '' );
    }

    return 1;
}

1;
