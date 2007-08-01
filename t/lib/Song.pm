use strict;
use warnings;

package # hide from PAUSE
	Song;

use base qw( Class::Observable );

sub new {
    my ( $class, $band, $name, $log ) = @_;
    my $self = bless {}, $class;
    %$self = (
        band      => $band,
        name      => $name,
        log       => $log,
        watchlist => $self->create_watchlist,
    );
    return $self;
}

sub FETCH_WATCHLIST { shift->{ watchlist } }

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
