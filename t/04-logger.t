#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Process;
use Capture::Tiny qw(capture_stdout);
use JSON::XS;

my $json = JSON::XS->new->utf8->allow_nonref;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sub reload_logger {
    delete $INC{'Rota/Logger.pm'};
    {
        # suppress warnings about reloading the logger module,
        # since we intentionally reload it multiple times with different environment settings
        local $SIG{__WARN__} = sub {
            warn @_ unless $_[0] =~ /Subroutine .* redefined/;
        };
        require Rota::Logger;
    }
    Rota::Logger->import(qw(log_info log_debug log_warn log_error log_fatal));
}

sub capture_log {
    my ($sub) = @_;
    return capture_stdout { $sub->() };
}

sub decode_json_log {
    my ($output) = @_;
    return $json->decode($output);
}

# ---------------------------------------------------------------------------
# JSON format tests (LOG_FORMAT=json)
# ---------------------------------------------------------------------------

subtest 'JSON format' => sub {

    local $ENV{LOG_FORMAT} = 'json';
    local $ENV{DEBUG}      = 0;
    reload_logger();

    subtest 'log_info' => sub {
        my $entry = decode_json_log( capture_log( sub { log_info('hello info') } ) );

        is $entry->{severity}, 'INFO',       'severity is INFO';
        is $entry->{message},  'hello info', 'message is correct';
        ok $entry->{timestamp}, 'timestamp is present';
        like $entry->{timestamp}, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, 'timestamp is ISO 8601 UTC format';
    };

    subtest 'log_warn' => sub {
        my $entry = decode_json_log( capture_log( sub { log_warn('something fishy') } ) );

        is $entry->{severity}, 'WARNING',         'severity is WARNING';
        is $entry->{message},  'something fishy', 'message is correct';
    };

    subtest 'log_error' => sub {
        my $entry = decode_json_log( capture_log( sub { log_error('it broke') } ) );

        is $entry->{severity}, 'ERROR',    'severity is ERROR';
        is $entry->{message},  'it broke', 'message is correct';
    };

    subtest 'log_fatal logs CRITICAL and exits' => sub {
        my ( $out, $exit );

        $out = capture_stdout {
            $exit = intercept_exit { log_fatal('something fatal') };
        };

        is $exit, 1, 'log_fatal exits with code 1';

        my $entry = decode_json_log($out);
        is $entry->{severity}, 'CRITICAL',        'severity is CRITICAL';
        is $entry->{message},  'something fatal', 'message is correct';
    };

    subtest 'log_debug' => sub {

        subtest 'suppressed when DEBUG not set' => sub {
            my $out = capture_log( sub { log_debug('quiet debug') } );
            is $out, '', 'no output when DEBUG is off';
        };

        subtest 'emitted when DEBUG=1' => sub {
            local $ENV{DEBUG} = 1;
            reload_logger();

            my $entry = decode_json_log( capture_log( sub { log_debug('verbose debug') } ) );

            is $entry->{severity}, 'DEBUG',         'severity is DEBUG';
            is $entry->{message},  'verbose debug', 'message is correct';
        };
    };

    subtest 'output structure' => sub {

        subtest 'is valid JSON' => sub {
            my $out = capture_log( sub { log_info('valid json check') } );
            chomp $out;
            ok lives { $json->decode($out) }, 'output is valid JSON';
        };

        subtest 'each entry is a single line' => sub {
            my $out   = capture_log( sub { log_info('one line') } );
            my @lines = grep {/\S/} split /\n/, $out;
            is scalar @lines, 1, 'exactly one line of output per log call';
        };
    };

    subtest 'message content' => sub {

        subtest 'multiline message is preserved' => sub {
            my $msg   = "line one\nline two\nline three";
            my $entry = decode_json_log( capture_log( sub { log_info($msg) } ) );
            is $entry->{message}, $msg, 'multiline message round-trips correctly through JSON';
        };

        subtest 'special characters are preserved' => sub {
            my $msg   = 'special chars: <>&"\'/\\';
            my $entry = decode_json_log( capture_log( sub { log_info($msg) } ) );
            is $entry->{message}, $msg, 'special characters preserved correctly';
        };
    };
};

# ---------------------------------------------------------------------------
# Text format tests (default, LOG_FORMAT unset)
# ---------------------------------------------------------------------------

subtest 'text format' => sub {

    subtest 'used by default when LOG_FORMAT not set' => sub {
        delete $ENV{LOG_FORMAT};
        reload_logger();

        my $out = capture_log( sub { log_info('default format') } );

        unlike $out, qr/^\{/,            'output is not JSON';
        like $out,   qr/INFO/,           'severity appears in output';
        like $out,   qr/default format/, 'message appears in output';
    };

    local $ENV{LOG_FORMAT} = 'text';
    reload_logger();

    subtest 'contains timestamp' => sub {
        my $out = capture_log( sub { log_info('timestamped') } );
        like $out, qr/\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, 'timestamp present in text output';
    };

    subtest 'no ANSI codes when not a terminal' => sub {
        my $out = capture_log( sub { log_info('no colours please') } );
        unlike $out, qr/\e\[/, 'no ANSI escape codes in non-terminal output';
    };

    subtest 'log_debug' => sub {

        subtest 'suppressed when DEBUG not set' => sub {
            local $ENV{DEBUG} = 0;
            reload_logger();

            my $out = capture_log( sub { log_debug('should be silent') } );
            is $out, '', 'no output when DEBUG is off';
        };

        subtest 'emitted when DEBUG=1' => sub {
            local $ENV{DEBUG} = 1;
            reload_logger();

            my $out = capture_log( sub { log_debug('text debug message') } );

            like $out, qr/DEBUG/,              'DEBUG severity in output';
            like $out, qr/text debug message/, 'message in output';
        };
    };
};

done_testing;
