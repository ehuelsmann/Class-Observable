use strict;

use Test::More tests => 15;

use Class::Observable;

BEGIN { @Something::ISA = qw( Class::Observable ); }

sub Something::new { bless {}, shift }

ok( Something->add_observer( 'Foo' ),  'Add observer to class ...' );
is( scalar Something->get_observers, 1, '... and check that it\'s there' );

my $omething = Something->new;
ok( $omething->add_observer( 'Bar' ),  'Add observer to instance' );
is( scalar $omething->get_direct_observers, 1, '... and check that it\'s there' );
is( scalar $omething->get_observers, 2, '... and that the instance sees both observers' );

my $omeotherthing = Something->new;
ok( $omething->copy_observers_to( $omeotherthing ), 'Copy observers from one instance to the other' );
is( scalar $omeotherthing->get_observers, 2, '... and check that the number of total observers on that instance is correct' );

ok( $omething->delete_direct_observers, 'Delete object-level observers' );
is( scalar $omething->get_direct_observers, 0, '... and check that they\'re gone' );
is( scalar $omething->get_observers, 1, '... but the instance still sees the class-level observer' );

ok( Something->delete_observer( 'Foo' ), 'Delete class-level observer' );
is( scalar $omething->get_observers, 0, '... and check that the first instance sees no observers anymore' );
is( scalar $omeotherthing->get_observers, 2, '... but the second one retains its instance copy of the class-level observer' );

ok( $omeotherthing->delete_direct_observers, 'Delete instance observers on second instance...' );
is( scalar $omeotherthing->get_observers, 0, '... and now it must not have any anymore' );
