use strict;
use warnings;

package # hide from PAUSE
	DeeJay;

sub new {
	my $class = shift;
	return bless { notification => 0 }, $class;
}

sub receive_notification {
	my $self = shift;
	my ( $song, $action ) = @_;
	$self->{notification}++;
}

sub num_notifications { shift->{notification} }

package # hide from PAUSE
	DeeJay::Playing;

@DeeJay::Playing::ISA = qw( DeeJay );

sub new {
	my $class = shift;
	my ( $playlist ) = @_;

	my $self = __PACKAGE__->SUPER::new( @_ );
	$self->{ playlist }          = $playlist || [];
	$self->{ current_song }      = -1;
	$self->{ songs_played } = 0;

	return $self;
}

sub play_next {
	my $self = shift;
	return if $self->{ current_song } == $#{ $self->{ playlist } };
	$self->{playlist}[ ++$self->{current_song} ]->play;
}

sub receive_notification {
	my $self = shift;
	my ( $song, $action ) = @_;
	$self->SUPER::receive_notification( @_ );
	if( $action eq 'end_song' ) {
		$self->{songs_played}++;
		$self->play_next;
	}
}

sub num_songs_played { shift->{songs_played} }

package # hide from PAUSE
	DeeJay::Selfish; # This DJ only responds to his/her own songs

@DeeJay::Selfish::ISA = qw( DeeJay );

sub new {
	my $class = shift;
	my ( $my_name ) = @_;

	my $self = __PACKAGE__->SUPER::new( @_ );
	$self->{ name } = $my_name;
	$self->{ notification_self } = 0;

	return $self;
}

sub receive_notification {
	my $self = shift;
	my ( $song, $action ) = @_;
	$self->SUPER::receive_notification( @_ );
	$self->{notification_self}++ if $song->{band} eq $self->{name};
}

sub num_notifications_self { shift->{notification_self} }

1;
