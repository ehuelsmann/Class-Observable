# -*-perl-*-

# $Id$

use strict;
use lib qw( ./t ./lib );
use Test::More  tests => 14;

require_ok( 'Class::Observable' );
require_ok( 'Song' );
require_ok( 'DeeJay' );

my @playlist = ( Song->new( 'U2', 'One' ),
                 Song->new( 'Moby', 'Ah Ah' ),
                 Song->new( 'Aimee Mann', 'How Am I Different' ),
                 Song->new( 'Everclear', 'Wonderful' ) );
my $dj      = DeeJay->new( \@playlist );
my $dj_moby = DeeJay::Selfish->new( 'Moby' );
my $dj_help = DeeJay::Helper->new();
is( Song->add_observer( $dj ), 1, 'Add main class-level observer' );
is( Song->add_observer( $dj_moby ), 2, 'Add secondary class-level observer' );
is( $playlist[0]->add_observer( $dj_help ), 1, 'Add object-level observer' );

$dj->start_party;

is( $dj->num_updates, 8, 'Total observations from starter' );
is( $dj->num_updates_stop, 4, 'Caught observations from starter' );
is( $dj_moby->num_updates, 8, 'Total observations from secondary' );
is( $dj_moby->num_updates_self, 2, 'Caught observations from secondary' );
is( $dj_help->num_updates, 2, 'Total observations from object-level observer' );

is( $playlist[0]->remove_all_observers, 1, 'Clear object-level observers' );
is( Song->remove_observer( $dj ), 1, 'Cleared object from class-level observers' );
is( Song->remove_all_observers(), 1, 'Cleared remaining class-level observers' );

