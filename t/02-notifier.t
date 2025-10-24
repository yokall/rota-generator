#!/usr/bin/env perl

use Test2::V0;
use DateTime;
use Email::Sender::Simple;
use Email::Sender::Transport::Test;

use Rota::Generator;
use Rota::Notifier;

subtest 'Send Rota Email' => sub {
    my $generator = Rota::Generator->new( names => [ 'Alice', 'Bob', 'Charlie' ] );

    my $start_date = DateTime->new(
        year  => 2025,
        month => 10,
        day   => 16,
    );

    my $assignments = $generator->generate_rota($start_date);

    my $test_transport = Email::Sender::Transport::Test->new;
    my $notifier       = Rota::Notifier->new(
        from      => 'rota@example.com',
        to        => 'me@example.com',
        transport => $test_transport,
    );

    ok( lives { $notifier->send_rota($assignments) }, 'Email sent without errors' );

    my @emails = $test_transport->deliveries;
    is( scalar @emails, 1, 'One email was sent' );

    # use Data::Dumper;
    # diag( Dumper( $emails[0]->{email} ) );

    my $email        = $emails[0];
    my $email_string = $email->{email}->as_string;

    like( $email_string, qr/^Subject: Rota Schedule/m,                     'Subject is correct' );
    like( $email_string, qr/^To: me\@example.com/m,                        'To address is correct' );
    like( $email_string, qr/Content-Type: text\/html/m,                    'Contains HTML part' );
    like( $email_string, qr/Content-Transfer-Encoding: quoted-printable/m, 'Has quoted-printable encoding' );
    like( $email_string, qr/<table/m,                                      'Contains HTML table' );

    # Verify the envelope information
    is( $email->{envelope}->{from},    'rota@example.com', 'Envelope from is correct' );
    is( $email->{envelope}->{to}->[0], 'me@example.com',   'Envelope to is correct' );
};

done_testing();
