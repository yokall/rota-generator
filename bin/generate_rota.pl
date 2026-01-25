#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use POSIX qw(strftime);
use Try::Tiny;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Rota::Generator;
use Rota::Notifier;
use Rota::Persistence;

unless ( $ENV{FORCE} ) {
    unless ( its_friday() ) {
        die "This script should only be run on Fridays\n";
    }
}

unless ( $ENV{ROTA_NAMES} ) {
    die "Please set ROTA_NAMES environment variable with comma-separated names\n";
}
my @names = split /\s*,\s*/, $ENV{ROTA_NAMES};    # Split on comma with optional whitespace

my $start_date;
if ( $ENV{START_DATE} ) {
    try {
        my ( $year, $month, $day ) = split /-/, $ENV{START_DATE};
        unless ( defined $year && defined $month && defined $day ) {
            die "Invalid START_DATE format";
        }
        $start_date = DateTime->new(
            year  => $year,
            month => $month,
            day   => $day,
        );
    }
    catch {
        die "Invalid START_DATE format. Please use YYYY-MM-DD format (e.g., 2025-10-16)\n";
    };
}
else {
    $start_date = DateTime->today();
}

my $generator   = Rota::Generator->new( names => \@names, persistence => Rota::Persistence->create() );
my $assignments = $generator->generate_rota($start_date);

print "\nRota Schedule:\n";
print "-" x 40 . "\n";
foreach my $assignment (@$assignments) {
    printf "%s: %s\n", $assignment->{date}->strftime('%A, %d %B %Y'), $assignment->{name};
}

try {
    my $notifier = Rota::Notifier->new( from => 'yokall@gmail.com', to => 'colincampbell321123@hotmail.com' );
    $notifier->send_rota($assignments);
    print "Rota has been generated and sent successfully!\n";

}
catch {
    die "Failed to send rota: $_\n";
};

sub its_friday {
    my $day_of_week = strftime( "%u", localtime );    # 1=Monday, 5=Friday

    return $day_of_week == 5;
}
