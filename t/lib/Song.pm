use strict;
use warnings;

package # hide from PAUSE
	Song;

use base qw( Class::Observable );

sub new {
    my ( $class, $band, $name, $log ) = @_;
    return bless( {
        band => $band,
        name => $name,
        log  => $log,
    }, $class );
}

sub play {
    my ( $self ) = @_;
    $self->notify_observers( 'start_play' );
    $self->{log} &&
        $self->{log}->( "Playing [$self->{name}] by [$self->{band}]" );
    $self->stop;
}

sub stop {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "Stopped [$self->{name}] by [$self->{band}]" );
    $self->notify_observers( 'stop_play' );
}

sub DESTROY {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "Destroying '$self->{name}'" );
}

1;
