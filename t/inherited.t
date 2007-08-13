use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Class::Observable;

use lib 't/lib';

BEGIN {
	package Parent;
	@Parent::ISA = qw( Class::Observable );
	sub new { my $self = bless {}, $_[0]; return $self }
	sub yodel { $_[0]->notify_observers }

	package Child;
	@Child::ISA = qw( Parent );
	sub yell { $_[0]->notify_observers }
}

my @receipt;
sub observer_a { push @receipt, "Parent notifies " . ref( $_[0] ) }
sub observer_b { push @receipt, "Child notifies " . ref( $_[0] ) }
sub observer_c { push @receipt, "Child instance notifies " . ref( $_[0] ) }

ok( Parent->add_observer( \&observer_a ), 'Add observer A to Parent' );
ok( Child->add_observer( \&observer_b ), 'Add observer B to Child' );

is( scalar Parent->get_observers, 1, 'One observer in Parent...' );
is( scalar Child->get_observers, 2, '... but two in Child' );

my $foo = Parent->new;
@receipt = ();
$foo->yodel;
is( $receipt[0], "Parent notifies Parent", "Catch notification from parent" );

my $baz_a = Child->new;
@receipt = ();
$baz_a->yell;
is( $receipt[0], "Child notifies Child", "Catch notification from child" );
is( $receipt[1], "Parent notifies Child", "Catch parent notification from child" );

my $baz_b = Child->new;
ok( $baz_b->add_observer( \&observer_c ), "Add observer C to instance" );
is( scalar $baz_b->get_observers, 3, "Count observers in instance + class" );

@receipt = ();
$baz_b->yell;
is( $receipt[0], "Child instance notifies Child", "Catch notification (instance) from child" );
is( $receipt[1], "Child notifies Child", "Catch notification (class) from child" );
is( $receipt[2], "Parent notifies Child", "Catch parent notification from child" );

my $baz_c = Child->new;
@receipt = ();
$baz_c->yell;
is( $receipt[0], "Child notifies Child", "Catch notification from child (after instance add)" );
is( $receipt[1], "Parent notifies Child", "Catch parent notification from child (after instance add)" );


is( $baz_b->delete_all_observers, 1, 'Delete instance observers' );
is( $baz_c->delete_all_observers, 0, 'Delete non-existent instance observers' );
is( Child->delete_all_observers, 1, 'Delete child observers' );
is( Parent->delete_all_observers, 1, 'Delete parent observers' );

done_testing;
