#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use POSIX qw(strftime);
use Try::Tiny;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Rota::Generator;
use Rota::Logger qw(log_info log_debug log_warn log_error log_fatal);
use Rota::Notifier;
use Rota::Persistence;

unless ( $ENV{FORCE} ) {
    unless ( its_friday() ) {
        log_fatal("This script should only be run on Fridays");
    }
}

unless ( $ENV{ROTA_NAMES} ) {
    log_fatal("Please set ROTA_NAMES environment variable with comma-separated names");
}
my @names = split /\s*,\s*/, $ENV{ROTA_NAMES};    # Split on comma with optional whitespace

log_debug( "Rota names: " . join( ", ", @names ) );

my $start_date;
if ( $ENV{START_DATE} ) {
    log_debug("Using START_DATE from environment: $ENV{START_DATE}");

    try {
        my ( $year, $month, $day ) = split /-/, $ENV{START_DATE};
        unless ( defined $year && defined $month && defined $day ) {
            log_fatal("Invalid START_DATE format");
        }
        $start_date = DateTime->new(
            year  => $year,
            month => $month,
            day   => $day,
        );
    }
    catch {
        log_fatal("Invalid START_DATE format. Please use YYYY-MM-DD format (e.g., 2025-10-16)");
    };
}
else {
    $start_date = DateTime->today();

    log_debug( "START_DATE, using today's date: " . $start_date->ymd );
}

my $generator   = Rota::Generator->new( names => \@names, persistence => Rota::Persistence->create() );
my $assignments = $generator->generate_rota($start_date);

my $schedule = "\nRota Schedule:\n";
$schedule .= "-" x 40 . "\n";
foreach my $assignment (@$assignments) {
    $schedule .= sprintf "%s: %s\n", $assignment->{date}->strftime('%A, %d %B %Y'), $assignment->{name};
}
log_info($schedule);

try {
    my $notifier = Rota::Notifier->new( from => 'yokall@gmail.com', to => 'colincampbell321123@hotmail.com' );
    $notifier->send_rota($assignments);
    log_info("Rota has been generated and sent successfully!");

}
catch {
    log_fatal("Failed to send rota: $_");
};

sub its_friday {
    my $day_of_week = strftime( "%u", localtime );    # 1=Monday, 5=Friday

    return $day_of_week == 5;
}
