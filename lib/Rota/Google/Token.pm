package Rota::Google::Token;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(get_gcloud_token);

sub get_gcloud_token {

    # Prefer explicit token if provided
    if ( $ENV{GCP_ACCESS_TOKEN} ) {
        return $ENV{GCP_ACCESS_TOKEN};
    }

    require HTTP::Tiny;

    my $key_file = $ENV{"GOOGLE_APPLICATION_CREDENTIALS"};
    if ( _file_exists($key_file) ) {

        # Create a signed JWT from the service account key and exchange it

        require Crypt::OpenSSL::RSA;
        require JSON::PP;
        require MIME::Base64;
        require Rota::FileIO;

        my $key_file_string = Rota::FileIO::read_file($key_file);
        my $service_account = JSON::PP::decode_json($key_file_string);

        my $header  = _build_header();
        my $payload = _build_payload($service_account);
        my $sig     = _build_signature( $service_account, $header, $payload );

        my $jwt = join( '.', $header, $payload, $sig );

        my $ua  = HTTP::Tiny->new( timeout => 10 );
        my $res = $ua->post_form( 'https://oauth2.googleapis.com/token', { grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion => $jwt } );
        if ( $res->{success} ) {
            my $data = JSON::PP::decode_json( $res->{content} );

            return $data->{access_token};
        }

        die "Token exchange failed: " . ( $res->{status} || '' ) . " - " . ( $res->{content} || '' );
    }

    # Fallback: metadata service (Cloud Run/GCE)
    my $ua  = HTTP::Tiny->new( timeout => 5 );
    my $res = $ua->get( 'http://metadata/computeMetadata/v1/instance/service-accounts/default/token', { headers => { 'Metadata-Flavor' => 'Google' } } );
    if ( $res->{success} ) {
        my $data = JSON::PP::decode_json( $res->{content} );

        return $data->{access_token};
    }

    die "Unable to get access token: metadata request failed ($res->{status})";
}

sub _file_exists {
    my $path = shift;

    if ( !defined $path ) {
        return 0;
    }

    return -f $path;
}

sub _encode_to_base64url {
    my ($data) = @_;
    my $b64 = MIME::Base64::encode_base64( $data, '' );

    # make output URL safe by replaceing '+' with '-' and '/' with '_'
    $b64 =~ tr[+/][-_];

    # trim tailing '='s
    $b64 =~ s/=+$//;

    return $b64;
}

sub _build_header {
    my $header = { alg => 'RS256', typ => 'JWT' };
    return _encode_to_base64url( JSON::PP::encode_json($header) );
}

sub _build_payload {
    my ($service_account) = @_;

    my $now    = int(time);
    my $claims = {
        iss   => $service_account->{client_email},
        scope => 'https://www.googleapis.com/auth/devstorage.read_write',
        aud   => 'https://oauth2.googleapis.com/token',
        exp   => $now + 3600,
        iat   => $now,
    };

    return _encode_to_base64url( JSON::PP::encode_json($claims) );
}

sub _build_signature {
    my ( $service_account, $header, $payload ) = @_;

    my $private_key = $service_account->{private_key} or die "Service account key missing private_key";
    my $rsa         = Crypt::OpenSSL::RSA->new_private_key($private_key);
    $rsa->use_sha256_hash();

    my $sig = $rsa->sign( join( '.', $header, $payload ) );

    return _encode_to_base64url($sig);
}

1;
