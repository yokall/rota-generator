package Rota::Persistence::File;

use strict;
use warnings;

use JSON::PP;
use DateTime;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Path qw(make_path);

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {
        dir      => $args{dir}      || _default_data_dir(),
        filename => $args{filename} || 'rota.json',
    }, $class;

    return $self;
}

sub _default_data_dir {
    my $script_path = abs_path( $0 // '' );
    my $script_dir  = $script_path ? dirname($script_path) : '.';

    return File::Spec->catdir( $script_dir, '..', 'data' );
}

sub _file_path {
    my ($self) = @_;

    unless ( -d $self->{dir} ) {
        make_path( $self->{dir} );
    }

    return File::Spec->catfile( $self->{dir}, $self->{filename} );
}

sub write_rota {
    my ( $self, $assignments ) = @_;
    my $file = $self->_file_path;

    # Convert DateTime objects to ISO date strings
    my $data = [ map { { date => $_->{date}->ymd, name => $_->{name} } } @$assignments ];

    open my $fh, '>', $file or die "Cannot open $file for writing: $!";
    print $fh encode_json($data);
    close $fh;

    return 1;
}

sub read_rota {
    my ($self) = @_;
    my $file = $self->_file_path;
    return unless -e $file;

    open my $fh, '<', $file or die "Cannot open $file for reading: $!";
    local $/;
    my $json = <$fh>;
    close $fh;

    my $data = eval { decode_json($json) };
    return unless $data && ref $data eq 'ARRAY';

    my @assignments = map {
        my $d = $_->{date};
        my ( $y, $m, $day ) = split /-/, $d;
        { date => DateTime->new( year => $y, month => $m, day => $day ), name => $_->{name} }
    } @$data;

    return \@assignments;
}

1;
