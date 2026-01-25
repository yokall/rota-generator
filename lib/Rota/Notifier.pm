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
        $self->{smtp} = $ENV{SMTP_HOST}     || die "SMTP host required";
        $self->{port} = $ENV{SMTP_PORT}     || die "SMTP port required";
        $self->{user} = $ENV{SMTP_USER}     || die "SMTP user required";
        $self->{pass} = $ENV{SMTP_PASSWORD} || die "SMTP password required";
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
        my $day      = $assignment->{date}->day;
        my $suffix   = $day =~ /1[123]$/ ? 'th' : $day =~ /1$/ ? 'st' : $day =~ /2$/ ? 'nd' : $day =~ /3$/ ? 'rd' : 'th';
        my $month    = $assignment->{date}->strftime('%b');
        my $date_str = "$month $day$suffix";
        $whatsapp_content .= sprintf( "%s - %s\n",                         $assignment->{date}->dmy('/'), $assignment->{name} );
        $table_rows       .= sprintf( "<tr><td>%s</td><td>%s</td></tr>\n", $date_str,                     $assignment->{name} );
    }

    $whatsapp_content = uri_escape($whatsapp_content);

    my $html = "<html><head><style>\n";
    $html .= "body { font-family: Arial, sans-serif; margin: 40px; padding: 20px; background-color: #f5f5f5; }\n";
    $html
        .= "table { width: 100%; max-width: 800px; margin: 0 auto; border-collapse: collapse; background-color: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\n";
    $html .= "th { font-size: 24px; font-weight: bold; padding: 20px; text-align: center; background-color: #333; color: white; border: 2px solid #333; }\n";
    $html .= "td { font-size: 20px; padding: 15px 20px; border: 1px solid #ddd; text-align: left; }\n";
    $html .= "tr:nth-child(even) { background-color: #f9f9f9; }\n";
    $html .= ".no-print { display: none; }\n";
    $html .= q{@media print { body { margin: 0; padding: 0; background-color: white; } .no-print { display: none !important; } }};
    $html .= "\n</style></head><body>\n";
    $html .= "<table border='1'>\n";
    $html .= "<tr><th colspan='2'>Recording Rota</th></tr>\n";
    $html .= $table_rows;
    $html
        .= '</table><p class="no-print" style="text-align: center; margin-top: 30px;"><a href="https://wa.me/'
        . '?text='
        . $whatsapp_content
        . '">Send Rota</a></p></body></html>';

    return $html;
}

sub send_rota {
    my ( $self, $assignments ) = @_;

    my $html = $self->_create_html_content($assignments);

    my $email = Email::MIME->create(
        header_str => [
            From    => $self->{from},
            To      => $self->{to},
            Subject => 'Recording Rota Update',
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
