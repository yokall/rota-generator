package Rota::Persistence;

use strict;
use warnings;

# Factory method to create persistence provider instances
# Provider can be specified via argument or PERSISTENCE_PROVIDER env var
# If neither is set, defaults to 'file'
sub create {
    my ( $class, %args ) = @_;
    my $provider = $args{provider} || $ENV{PERSISTENCE_PROVIDER} || 'file';

    if ( $provider eq 'file' ) {
        require Rota::Persistence::File;
        return Rota::Persistence::File->new( %{ $args{file_opts} || {} } );
    }

    die "Unknown persistence provider: $provider";
}

1;
