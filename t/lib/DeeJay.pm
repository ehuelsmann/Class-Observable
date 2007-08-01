use strict;
use warnings;

package # hide from PAUSE
	DeeJay;

sub new {
    my ( $class, $playlist, $log ) = @_;
    $playlist ||= [];
    return bless( {
        playlist  => $playlist,
        num_songs => scalar @{ $playlist },
        $log      => $log,
    }, $class );
}

sub start_party {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "Let's get this party started!" );
    $self->{current_song} = 0;
    $self->{playlist}[0]->play;
}

sub end_party {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "Party's over, time to go home" );
}

sub receive_notification {
    my ( $self, $song, $action ) = @_;
    $self->{log} &&
        $self->{log}->( "Caught notification [$action] from [$song->{band}]" );
    $self->{notification}++;
    return unless ( $action eq 'stop_play' );
    $self->{notification_stop}++;
    $self->{current_song}++;
    if ( $self->{current_song} == $self->{num_songs} ) {
        return $self->end_party;
    }
    $self->{playlist}[ $self->{current_song} ]->play;
}

sub num_notifications      { return $_[0]->{notification} }
sub num_notifications_stop { return $_[0]->{notification_stop} }

sub DESTROY {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "DeeJay retiring" );
}

package # hide from PAUSE
	DeeJay::Selfish;

# This DJ only responds to his/her own songs

sub new {
    my ( $class, $my_name, $log ) = @_;
    return bless({
        name        => $my_name,
        notification      => 0,
        notification_self => 0,
        log         => $log,
    }, $class );
}

sub receive_notification {
    my ( $self, $song ) = @_;
    $self->{notification}++;
    $self->{log} &&
        $self->{log}->( "I am '$self->{name}' song is '$song->{band}'" );
    $self->{notification_self}++ if ( $song->{band} eq $self->{name} );
}

sub num_notifications      { return $_[0]->{notification} }
sub num_notifications_self { return $_[0]->{notification_self} }

package # hide from PAUSE
	DeeJay::Helper;

sub new {
    my ( $class, $log ) = @_;
    return bless({
        log => $log,
    }, $class );
}

sub receive_notification {
    my ( $self, $song ) = @_;
    $self->{notification}++;
}

sub num_notifications { return $_[0]->{notification} }

1;
