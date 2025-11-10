package Rota::Notifier;

use strict;
use warnings;

use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Try::Tiny;
use URI::Escape;

my $DEBUG = 0;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        config    => $args{config},
        from      => $args{from},
        to        => $args{to},
        transport => $args{transport},    # Optional transport for testing
    };

    bless $self, $class;

    # Only load config if we don't pass in transport, for example for testing
    unless ( $self->{transport} ) {
        $self->_load_config();
    }

    die "From address required" unless $self->{from};
    die "To address required"   unless $self->{to};

    return $self;
}

sub _load_config {
    my ($self) = @_;

    try {
        use Data::Dumper;
        warn Dumper( $self->{config} ) if $DEBUG;

        # Load SMTP settings with environment variable override for password
        $self->{smtp} = $self->{config}{smtp}{host} || die "SMTP host required";
        $self->{port} = $self->{config}{smtp}{port} || 587;
        $self->{user} = $self->{config}{smtp}{user} || die "SMTP user required";
        $self->{pass} = $ENV{SMTP_PASSWORD}         || $self->{config}{smtp}{pass} || die "SMTP password required";
    }
    catch {
        die "Failed to load config: $_";
    };

    return;
}

sub _create_html_content {
    my ( $self, $assignments ) = @_;

    my $whatsapp_content = "Recording Rota:\n";
    my $table_rows;
    foreach my $assignment ( @{$assignments} ) {
        $whatsapp_content .= sprintf( "%s - %s\n",                         $assignment->{date}->dmy('/'), $assignment->{name} );
        $table_rows       .= sprintf( "<tr><td>%s</td><td>%s</td></tr>\n", $assignment->{date}->dmy('/'), $assignment->{name} );
    }

    $whatsapp_content = uri_escape($whatsapp_content);

    my $html = "<html><body>\n";
    $html .= "<h1>Rota Schedule</h1>\n";
    $html .= "<table border='1'>\n";
    $html .= "<tr><th>Date</th><th></th></tr>\n";
    $html .= $table_rows;
    $html .= '</table><p><a href="https://wa.me/' . '?text=' . $whatsapp_content . '">Send Rota</a></p></body></html>';

    return $html;
}

sub send_rota {
    my ( $self, $assignments ) = @_;

    my $html = $self->_create_html_content($assignments);

    my $email = Email::MIME->create(
        header_str => [
            From    => $self->{from},
            To      => $self->{to},
            Subject => 'Rota Schedule Update',
        ],
        parts => [
            Email::MIME->create(
                attributes => {
                    content_type => 'text/html',
                    encoding     => 'quoted-printable',
                    charset      => 'UTF-8',
                },
                body_str => $html,
            )
        ],
    );

    my $transport = $self->{transport};
    unless ($transport) {
        print "Debug: Setting up SMTP transport for $self->{smtp}:$self->{port}\n" if $DEBUG;
        print "Debug: Using username: $self->{user}\n"                             if $DEBUG;

        $transport = Email::Sender::Transport::SMTP->new(
            {   host          => $self->{smtp},
                port          => $self->{port},
                ssl           => 'starttls',
                sasl_username => $self->{user},
                sasl_password => $self->{pass},
                debug         => $DEBUG,
            }
        );
    }

    sendmail(
        $email,
        {   transport => $transport,
            to        => $self->{to},
            from      => $self->{from},
        }
    );

    return;
}

1;
