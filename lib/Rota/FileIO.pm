package Rota::FileIO;

use strict;
use warnings;

sub read_file {
    my ($path) = @_;

    open my $fh, '<', $path or die "Cannot open file $path: $!";
    local $/;
    my $content = <$fh>;
    close $fh;

    return $content;
}

1;
