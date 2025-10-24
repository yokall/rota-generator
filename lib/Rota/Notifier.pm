package Rota::Notifier;

use strict;
use warnings;

use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use YAML::XS qw(LoadFile);
use Try::Tiny;

my $DEBUG = 0;

sub new {
    my ( $class, %args ) = @_;

    my $self = {
        config_file => $args{config_file} || 'config.yml',
        from        => $args{from},
        to          => $args{to},
        transport   => $args{transport},                     # Optional transport for testing
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
        my $config = LoadFile( $self->{config_file} );

        # Load SMTP settings
        $self->{smtp} = $config->{smtp}{host} || die "SMTP host required";
        $self->{port} = $config->{smtp}{port} || 587;
        $self->{user} = $config->{smtp}{user} || die "SMTP user required";
        $self->{pass} = $config->{smtp}{pass} || die "SMTP password required";
    }
    catch {
        die "Failed to load config: $_";
    };

    return;
}

sub _create_html_content {
    my ( $self, $assignments ) = @_;

    my $html = "<html><body>\n";
    $html .= "<h1>Rota Schedule</h1>\n";
    $html .= "<table border='1'>\n";
    $html .= "<tr><th>Date</th><th></th></tr>\n";

    for my $assignment (@$assignments) {
        $html .= sprintf( "<tr><td>%s</td><td>%s</td></tr>\n", $assignment->{date}->strftime('%A, %d %B %Y'), $assignment->{name} );
    }

    $html .= "</table></body></html>";
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
