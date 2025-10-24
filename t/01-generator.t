#!/usr/bin/env perl

use Test2::V0;

use DateTime;

use Rota::Generator;

subtest 'Calculate Sundays' => sub {
    my $generator = Rota::Generator->new();

    my $start_date = DateTime->new(
        year  => 2025,
        month => 10,
        day   => 16,
    );

    my $sundays = $generator->get_upcoming_sundays($start_date);

    # Expected Sundays for next 2 months from Oct 16, 2025:
    # Oct: 19, 26
    # Nov: 2, 9, 16, 23, 30
    # Dec: 7, 14, 21, 28
    is( scalar @$sundays, 11, 'Found correct number of Sundays' );

    is( $sundays->[0]->ymd,  '2025-10-19', 'Date 1 is correct' );
    is( $sundays->[1]->ymd,  '2025-10-26', 'Date 2 is correct' );
    is( $sundays->[2]->ymd,  '2025-11-02', 'Date 3 is correct' );
    is( $sundays->[3]->ymd,  '2025-11-09', 'Date 4 is correct' );
    is( $sundays->[4]->ymd,  '2025-11-16', 'Date 5 is correct' );
    is( $sundays->[5]->ymd,  '2025-11-23', 'Date 6 is correct' );
    is( $sundays->[6]->ymd,  '2025-11-30', 'Date 7 is correct' );
    is( $sundays->[7]->ymd,  '2025-12-07', 'Date 8 is correct' );
    is( $sundays->[8]->ymd,  '2025-12-14', 'Date 9 is correct' );
    is( $sundays->[9]->ymd,  '2025-12-21', 'Date 10 is correct' );
    is( $sundays->[10]->ymd, '2025-12-28', 'Date 11 is correct' );
};

subtest 'Name Assignment' => sub {
    my $generator = Rota::Generator->new( names => [ 'Alice', 'Bob', 'Charlie' ] );

    my $start_date = DateTime->new(
        year  => 2025,
        month => 10,
        day   => 16,
    );

    my $assignments = $generator->generate_rota($start_date);

    is( ref $assignments, 'ARRAY', 'Returns array of assignments' );
    ok( scalar @$assignments > 0, 'Has assignments' );

    is( $assignments->[0]->{name}, 'Alice',   'First person assigned' );
    is( $assignments->[1]->{name}, 'Bob',     'Second person assigned' );
    is( $assignments->[2]->{name}, 'Charlie', 'Third person assigned' );
    is( $assignments->[3]->{name}, 'Alice',   'Rotation starts over' );
};

done_testing();
