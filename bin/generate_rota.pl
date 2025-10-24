#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Try::Tiny;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Rota::Generator;
use Rota::Notifier;

my @names = ( 'Alice', 'Bob', 'Charlie' );

my $generator = Rota::Generator->new( names => \@names );

my $start_date  = DateTime->now();
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
