package Rota::Generator;

use strict;
use warnings;

use DateTime;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Path qw(make_path);

sub new {
    my ( $class, %args ) = @_;

    return bless {
        names          => $args{names} || [],
        _current_index => 0,
    }, $class;
}

sub get_upcoming_sundays {
    my ( $self, $start_date ) = @_;

    my $date = _get_next_sunday($start_date);

    # Find the last Sunday of the month two months ahead
    my $last_day = _get_end_date($start_date);

    my @sundays;
    while ( $date <= $last_day ) {
        push @sundays, $date->clone;
        $date->add( days => 7 );
    }

    return \@sundays;
}

sub _get_next_sunday {
    my $start_date = shift;

    my $date = $start_date->clone;

    # Move to next Sunday if not already on Sunday
    $date->add( days => 1 ) until $date->day_of_week == 7;

    return $date;
}

sub _get_end_date {
    my $start_date = shift;

    my $end_month = $start_date->clone->add( months => 2 );
    my $last_day  = DateTime->last_day_of_month(
        year  => $end_month->year,
        month => $end_month->month,
    );

    # Move backwards to find last Sunday
    while ( $last_day->day_of_week != 7 ) {
        $last_day->subtract( days => 1 );
    }

    return $last_day;
}

sub _next_name {
    my ($self) = @_;

    my $name = $self->{names}->[ $self->{_current_index} ];
    $self->{_current_index} = ( $self->{_current_index} + 1 ) % @{ $self->{names} };

    return $name;
}

sub generate_rota {
    my ( $self, $start_date ) = @_;

    my $sundays = $self->get_upcoming_sundays($start_date);

    my $rota = [ map { { date => $_, name => $self->_next_name(), } } @$sundays ];

    persist_rota($rota);

    return $rota;
}

sub _get_rota_filepath {
    my $script_path = abs_path( $0 // '' );
    my $script_dir  = $script_path ? dirname($script_path) : '.';
    my $data_dir    = File::Spec->catdir( $script_dir, '..', 'data' );

    make_path($data_dir) unless -d $data_dir;

    return File::Spec->catfile( $data_dir, 'rota.txt' );
}

sub persist_rota {
    my ($assignments) = @_;

    my $file_path = _get_rota_filepath();

    open my $fh, '>', $file_path or die "Could not open file '$file_path': $!";
    foreach my $assignment (@$assignments) {
        printf $fh "%s:%s\n", $assignment->{date}->ymd, $assignment->{name};
    }
    close $fh;

    return;
}

1;
