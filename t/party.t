use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Class::Observable;

use lib 't/lib';
use Song;
use DeeJay;

my $last_message;
my $log = sub { $last_message = $_[0] };

my @playlist = (
	Song->new( 'U2', 'One', $log ),
	Song->new( 'Moby', 'Ah Ah', $log  ),
	Song->new( 'Aimee Mann', 'How Am I Different', $log ),
	Song->new( 'Everclear', 'Wonderful', $log  ),
);

my $dj      = DeeJay->new( \@playlist, $log );
my $dj_moby = DeeJay::Selfish->new( 'Moby', $log );
my $dj_help = DeeJay::Helper->new( $log );

is( Song->add_observer( $dj ), 1, 'Add main class-level observer' );
is( Song->add_observer( $dj_moby ), 2, 'Add secondary class-level observer' );
is( $playlist[0]->add_observer( $dj_help ), 1, 'Add object-level observer' );

is( scalar Song->get_observers, 2, 'Count class-level observers' );
is( scalar $playlist[0]->get_observers, 3, 'Count object-level + class-level observers' );

$dj->start_party;

is( $dj->num_notifications, 8, 'Total observations from starter' );
is( $dj->num_notifications_stop, 4, 'Catch observations from starter' );
is( $dj_moby->num_notifications, 8, 'Count observations from secondary' );
is( $dj_moby->num_notifications_self, 2, 'Catch observations from secondary' );
is( $dj_help->num_notifications, 2, 'Count observations from object-level observer' );

my $num_prev_observers = $playlist[1]->get_observers;
$playlist[0]->copy_observers_to( $playlist[1] );
is( $playlist[1]->get_observers - $num_prev_observers, 1, 'Copied correct number of observers' );
is( scalar $playlist[1]->get_observers, 3, 'New object has correct number of observers' );

is( $playlist[0]->delete_all_observers, 1, 'Delete object-level observers' );
is( $playlist[1]->delete_all_observers, 3, 'Delete object-level observers' );
is( Song->delete_observer( $dj ), 1, 'Delete object from class-level observers' );
is( Song->delete_all_observers, 1, 'Delete remaining class-level observers' );

done_testing;
