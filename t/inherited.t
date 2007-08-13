use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Class::Observable;

use lib 't/lib';

BEGIN {
	@Parent::ISA = qw( Class::Observable );
	@Child::ISA  = qw( Parent );

	sub Parent::new { my $self = bless {}, $_[0]; return $self }

	my @receipt;

	sub recipient {
		my ( $recipient ) = @_;
		sub {
			my $sender_obj = shift;
			my $sender = ref( $sender_obj ) || $sender_obj;
			push @receipt, "$sender notifies $recipient observers";
		};
	}

	sub microphone_check {
		my ( $sender_obj ) = @_;
		@receipt = ();
		return $sender_obj->notify_observers;
	}

	sub num_received {
		scalar @receipt;
	}

	sub received {
		my ( $msg ) = @_;
		scalar grep { $_ eq $msg } @receipt;
	}
}

ok( Parent->add_observer( recipient 'Parent' ), 'Add observer to Parent ...' );
is( scalar Parent->get_direct_observers, 1, '... and check that it has one' );
is( scalar Parent->get_observers, 1, '... and there is only one in total' );

ok( microphone_check( 'Parent' ), 'Trigger notification to Parent observers...' );
ok( received( 'Parent notifies Parent observers' ), '... and check that they get it' );

ok( Child->add_observer( recipient 'Child' ), 'Add observer to Child' );
is( scalar Child->get_direct_observers, 1, '... and check that it has one' );
is( scalar Child->get_observers, 2, '... and that it inherits Parent\'s observer' );

ok( microphone_check( 'Child' ), 'Trigger notification to Child observers...' );
ok( received( 'Child notifies Child observers' ), '... and check that they get it' );
ok( received( 'Child notifies Parent observers' ), '... as well as the superclass observers' );

my $ch1 = Child->new;
my $ch2 = Child->new;
ok( $ch2->add_observer( recipient 'Child instance' ), 'Add observer to instance ...' );
is( scalar $ch2->get_direct_observers, 1, '... and see that it has one' );
is( scalar $ch2->get_observers, 3, '... and that instance + class is the correct total' );
is( scalar $ch1->get_direct_observers, 0, '... and that no other instance is affected' );
is( scalar $ch1->get_observers, 2, '... nor the number of class-level observers' );

ok( microphone_check( $ch2 ), 'Trigger notification to the instance observers...' );
ok( received( 'Child notifies Child instance observers' ), '... and check that they get it' );
ok( received( 'Child notifies Child observers' ), '... as well as the class observers' );
ok( received( 'Child notifies Parent observers' ), '... and the superclass observers' );

ok( $ch2->delete_direct_observers, 'Delete instance observers...' );
is( scalar $ch2->get_direct_observers, 0, '... and check that it has none' );
is( scalar $ch2->get_observers, 2, '... but its inherited observers are unaffected' );

ok( Child->delete_direct_observers, 'Delete Child observers...' );
is( scalar Child->get_direct_observers, 0, '... and check that it has none' );
is( scalar $ch2->get_observers, 1, '... and that that this affects instances also' );

ok( Parent->delete_direct_observers, 'Delete parent observers...' );
is( scalar Parent->get_direct_observers, 0, '... and check that it has none' );
is( scalar $ch2->get_observers, 0, '... and that that this affects instances also' );

done_testing;
