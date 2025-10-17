#!/usr/bin/env perl

use Test2::V0;

use DateTime;

# Load our module
use Rota::Generator;

subtest 'Calculate Sundays' => sub {
    my $generator = Rota::Generator->new();

    # Test with a known date (using your current date as reference)
    my $start_date = DateTime->new(
        year  => 2025,
        month => 10,
        day   => 16,
    );

    my $sundays = $generator->get_upcoming_sundays($start_date);

    # Expected Sundays for next 2 months from Oct 16, 2025:
    # Oct: 19, 26
    # Nov: 2, 9, 16, 23, 30
    # Dec: 7, 14
    is( scalar @$sundays, 9, 'Found correct number of Sundays' );

    # Test first and last dates
    is( $sundays->[0]->ymd, '2025-10-19', 'First Sunday is correct' );
    is( $sundays->[8]->ymd, '2025-12-14', 'Last Sunday is correct' );
};

subtest 'Name Assignment' => sub {
    my $generator = Rota::Generator->new( names => [ 'Alice', 'Bob', 'Charlie' ] );

    my $start_date = DateTime->new(
        year  => 2025,
        month => 10,
        day   => 16,
    );

    my $assignments = $generator->generate_rota($start_date);

    # Test the structure of assignments
    is( ref $assignments, 'ARRAY', 'Returns array of assignments' );
    ok( scalar @$assignments > 0, 'Has assignments' );

    # Test first assignment
    is( $assignments->[0]->{date}->ymd, '2025-10-19', 'First assignment date' );
    is( $assignments->[0]->{name},      'Alice',      'First person assigned' );

    # Test rotation of names
    is( $assignments->[1]->{name}, 'Bob',     'Second person assigned' );
    is( $assignments->[2]->{name}, 'Charlie', 'Third person assigned' );
    is( $assignments->[3]->{name}, 'Alice',   'Rotation starts over' );
};

done_testing();
