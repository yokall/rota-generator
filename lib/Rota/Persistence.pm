package Rota::Persistence;

use strict;
use warnings;

use Rota::Logger qw(log_info log_debug log_warn log_error log_fatal);

# Factory method to create persistence provider instances
# Provider can be specified via argument or PERSISTENCE_PROVIDER env var
# If neither is set, defaults to 'file'
sub create {
    my ( $class, %args ) = @_;
    my $provider = $args{provider} || $ENV{PERSISTENCE_PROVIDER} || 'file';

    log_debug("Creating persistence provider: $provider");

    if ( $provider eq 'file' ) {
        require Rota::Persistence::File;
        return Rota::Persistence::File->new( %{ $args{file_opts} || {} } );
    }

    if ( $provider eq 'gcs' ) {
        require Rota::Persistence::GCS;
        return Rota::Persistence::GCS->new( %{ $args{gcs_opts} || {} } );
    }

    log_fatal("Unknown persistence provider: $provider");
}

1;
