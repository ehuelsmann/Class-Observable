use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Class::Observable;

use lib 't/lib';
use Song;
use DeeJay;

my @playlist = map Song->new( @$_ ), (
	[ 'U2', 'One' ],
	[ 'Moby', 'Ah Ah' ],
	[ 'Aimee Mann', 'How Am I Different' ],
	[ 'Everclear', 'Wonderful' ],
);

my $dj       = DeeJay::Playing->new( \@playlist );
my $dj_moby  = DeeJay::Selfish->new( 'Moby' );
my $dj_guest = DeeJay->new();

ok( Song->add_observer( $dj ), 'Add main class-level observer...' );
ok( Song->add_observer( $dj_moby ), '... and secondary one' );
is( scalar Song->get_observers, 2, '... and check that the number of class-level observers is right' );

is( $playlist[0]->add_observer( $dj_guest ), 1, 'Add instance observer' );
is( scalar $playlist[0]->get_observers, 3, '... and check that the instance sees the right total of observers' );

$dj->play_next;

is( $dj->num_notifications, 2 * @playlist, 'Main DJ got notified of start and end for all songs...' );
is( $dj->num_songs_played, 1 * @playlist, '... and for the end of them all' );

is( $dj_moby->num_notifications, 2 * @playlist, 'Secondary DJ got notified of start and end for all songs...' );
is( $dj_moby->num_notifications_self, 2 * ( grep { $_->band eq 'Moby' } @playlist ), '... and recognised notifications for his own songs' );

is( $dj_guest->num_notifications, 2, 'Guest got notified about start and end of the song instance he was interested in' );

my $num_prev_observers = $playlist[1]->get_observers;
$playlist[0]->copy_observers_to( $playlist[1] );
is( $playlist[1]->get_observers - $num_prev_observers, 1, 'Copied correct number of observers' );
is( scalar $playlist[1]->get_observers, 3, 'New object has correct number of observers' );

is( $playlist[0]->delete_direct_observers, 1, 'Delete object-level observers' );
is( $playlist[1]->delete_direct_observers, 3, 'Delete object-level observers' );
is( Song->delete_observer( $dj ), 1, 'Delete object from class-level observers' );
is( Song->delete_direct_observers, 1, 'Delete remaining class-level observers' );

done_testing;
