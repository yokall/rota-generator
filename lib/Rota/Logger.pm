package Rota::Logger;

use strict;
use warnings;

use JSON::XS;
use POSIX qw(strftime);
use Exporter 'import';

our @EXPORT_OK = qw(log_info log_debug log_warn log_error log_fatal);

my $DEBUG      = $ENV{DEBUG}      ? 1                : 0;
my $LOG_FORMAT = $ENV{LOG_FORMAT} ? $ENV{LOG_FORMAT} : 'text';    # 'text' or 'json'
my $USE_COLOUR = -t STDOUT        ? 1                : 0;

my $json = JSON::XS->new->utf8->allow_nonref;

my %COLOURS = (
    DEBUG    => "\e[36m",    # cyan
    INFO     => "\e[32m",    # green
    WARNING  => "\e[33m",    # yellow
    ERROR    => "\e[31m",    # red
    CRITICAL => "\e[35m",    # magenta
);
my $RESET = "\e[0m";

sub _log {
    my ( $severity, $message ) = @_;

    if ( $LOG_FORMAT eq 'json' ) {
        my $entry = {
            severity  => $severity,
            message   => $message,
            timestamp => strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime ),
        };
        say STDOUT $json->encode($entry);
    }
    else {
        my $timestamp = strftime( '%Y-%m-%d %H:%M:%S', localtime );
        my $colour    = $USE_COLOUR ? ( $COLOURS{$severity} // '' ) : '';
        my $reset     = $USE_COLOUR ? $RESET                        : '';
        printf STDOUT "%s %s%-8s%s %s\n", $timestamp, $colour, $severity, $reset, $message;
    }
}

sub log_info { _log( 'INFO', $_[0] ) }

sub log_warn { _log( 'WARNING', $_[0] ) }

sub log_error { _log( 'ERROR', $_[0] ) }

sub log_fatal {
    my ($message) = @_;
    _log( 'CRITICAL', $message );
    exit 1;
}

sub log_debug { _log( 'DEBUG', $_[0] ) if $DEBUG }

1;
