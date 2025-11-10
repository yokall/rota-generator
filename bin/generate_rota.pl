#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use Try::Tiny;
use YAML::XS qw(LoadFile);

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Rota::Generator;
use Rota::Notifier;

my $config_file = "$Bin/config.yml";
my $config;
try {
    $config = LoadFile($config_file);
}
catch {
    die "Failed to load config: $_";
};

my @names = @{ $config->{names} };

my $generator = Rota::Generator->new( names => \@names );

my $start_date  = DateTime->today();
my $assignments = $generator->generate_rota($start_date);

print "\nRota Schedule:\n";
print "-" x 40 . "\n";
foreach my $assignment (@$assignments) {
    printf "%s: %s\n", $assignment->{date}->strftime('%A, %d %B %Y'), $assignment->{name};
}

try {
    my $notifier = Rota::Notifier->new( from => 'yokall@gmail.com', to => 'colincampbell321123@hotmail.com', config => $config );
    $notifier->send_rota($assignments);
    print "Rota has been generated and sent successfully!\n";

}
catch {
    die "Failed to send rota: $_\n";
};
