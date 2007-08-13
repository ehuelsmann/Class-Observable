use strict;
use warnings;

package # hide from PAUSE
	Song;

use base qw( Class::Observable );

sub new {
	my $class = shift;
	my ( $band, $name ) = @_;
	return bless {
		band => $band,
		name => $name,
	}, $class;
}

sub play {
	my $self = shift;
	$self->notify_observers( 'begin_song' );
	$self->notify_observers( 'end_song' );
}

sub band { shift->{ band } }
sub name { shift->{ name } }

1;
