#!/usr/bin/env perl

use Test2::V0;

use File::Spec;
use File::Basename;

my $bin_dir = File::Spec->catfile( dirname(__FILE__), '..', 'bin' );
my $script  = File::Spec->catfile( $bin_dir, 'generate_rota.pl' );

subtest 'Invalid START_DATE format' => sub {
    my @invalid_dates = (
        '2025-13-01',    # Invalid month
        '2025-10',       # Missing day
        'not-a-date',    # Invalid format
        '2025/10/16',    # Wrong separator
    );

    foreach my $invalid_date (@invalid_dates) {
        my $cmd    = "FORCE=1 ROTA_NAMES='Alice,Bob' START_DATE='$invalid_date' perl '$script' 2>&1";
        my $output = `$cmd`;

        like( $output, qr/Invalid START_DATE format|month|invalid|range/i, "Invalid START_DATE '$invalid_date' produces error message" );
    }
};

done_testing();
