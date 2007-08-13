use strict;
use warnings;

use Test::More 0.88; # for done_testing
use Class::Observable;

use lib 't/lib';

BEGIN {
	package Foo;
	@Foo::ISA = qw( Class::Observable );
	sub new { my $self = bless {}, $_[0]; return $self }
	sub yodel { $_[0]->notify_observers }

	package Baz;
	@Baz::ISA = qw( Foo );
	sub yell { $_[0]->notify_observers }
}

my @observations = ();
sub observer_a { push @observations, "Observation A from [" . ref( $_[0] ) . "]" }
sub observer_b { push @observations, "Observation B from [" . ref( $_[0] ) . "]" }
sub observer_c { push @observations, "Observation C from [" . ref( $_[0] ) . "]" }

ok( Foo->add_observer( \&observer_a ), 'Add observer A to Foo' );
ok( Baz->add_observer( \&observer_b ), 'Add observer B to Baz' );

is( scalar Foo->get_observers, 1, 'One observer in Foo...' );
is( scalar Baz->get_observers, 2, '... but two in Baz' );

my $foo = Foo->new;
$foo->yodel;
is( $observations[0], "Observation A from [Foo]", "Catch notification from parent" );

my $baz_a = Baz->new;
@observations = ();
$baz_a->yell;
is( $observations[0], "Observation B from [Baz]", "Catch notification from child" );
is( $observations[1], "Observation A from [Baz]", "Catch parent notification from child" );

my $baz_b = Baz->new;
ok( $baz_b->add_observer( \&observer_c ), "Add observer C to object" );
is( scalar $baz_b->get_observers, 3, "Count observers in object + class" );

@observations = ();
$baz_b->yell;
is( $observations[0], "Observation C from [Baz]", "Catch notification (object) from child" );
is( $observations[1], "Observation B from [Baz]", "Catch notification (class) from child" );
is( $observations[2], "Observation A from [Baz]", "Catch parent notification from child" );

my $baz_c = Baz->new;
@observations = ();
$baz_c->yell;
is( $observations[0], "Observation B from [Baz]", "Catch notification from child (after object add)" );
is( $observations[1], "Observation A from [Baz]", "Catch parent notification from child (after object add)" );


is( $baz_b->delete_all_observers, 1, 'Delete object observers' );
is( $baz_c->delete_all_observers, 0, 'Delete non-existent object observers' );
is( Baz->delete_all_observers, 1, 'Delete child observers' );
is( Foo->delete_all_observers, 1, 'Delete parent observers' );

done_testing;
