package Rota::Generator;
use strict;
use warnings;

use DateTime;

sub new {
    my ( $class, %args ) = @_;

    return bless {
        names          => $args{names} || [],
        _current_index => 0,
    }, $class;
}

sub get_upcoming_sundays {
    my ( $self, $start_date ) = @_;

    my @sundays;
    my $date = $start_date->clone;

    # Move to next Sunday if not already on Sunday
    $date->add( days => 1 ) until $date->day_of_week == 7;

    # Collect Sundays for next 2 months
    my $end_date = $start_date->clone->add( months => 2 );
    while ( $date < $end_date ) {
        push @sundays, $date->clone;
        $date->add( days => 7 );
    }

    return \@sundays;
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

    return [ map { { date => $_, name => $self->_next_name(), } } @$sundays ];
}

1;
