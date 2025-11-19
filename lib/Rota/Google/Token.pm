package Rota::Google::Token;

use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw(get_gcloud_token);

sub get_gcloud_token {
    my $key_file = $ENV{"GOOGLE_APPLICATION_CREDENTIALS"};
    if ( $key_file && -f $key_file ) {
        system("gcloud auth activate-service-account --key-file $key_file >/dev/null 2>&1");
        my $token = `gcloud auth print-access-token 2>/dev/null`;
        chomp $token;
        return $token if $token;
    }

    # Cloud Run / GCE path: get token from metadata service using HTTP::Tiny
    require HTTP::Tiny;
    require JSON::PP;
    my $ua  = HTTP::Tiny->new( timeout => 5 );
    my $res = $ua->get( 'http://metadata/computeMetadata/v1/instance/service-accounts/default/token', { headers => { 'Metadata-Flavor' => 'Google' } } );

    if ( $res->{success} ) {
        my $data  = eval { JSON::PP::decode_json( $res->{content} ) };
        my $token = $data->{access_token} if $data && ref $data eq 'HASH';

        warn "Got token: $token";

        die "Unable to get access token from metadata service" unless $token;
        return $token;
    }

    die "Unable to get access token: metadata request failed ($res->{status})";
}

1;
