# -*-perl-*-

# $Id$

use strict;
use lib qw( ./t ./lib );
use Test::More  tests => 6;

BEGIN {
    package Foo;
    use base qw( Class::Observable );
    sub new { return bless( {}, $_[0] ) }
    sub yodel { $_[0]->notify_observers }

    package Baz;
    use base qw( Foo );
    sub yell { $_[0]->notify_observers }
}

require_ok( 'Class::Observable' );

my @observations = ();
sub observer_a { push @observations, "Observation A from [" . ref( $_[0] ) . "]" }
sub observer_b { push @observations, "Observation B from [" . ref( $_[0] ) . "]" }

is( Foo->add_observer( \&observer_a ), 1, "Add observer A" );
is( Baz->add_observer( \&observer_b ), 1, "Add observer B" );

my $foo = Foo->new;
$foo->yodel;
is( $observations[0], "Observation A from [Foo]", "Catch notification from parent" );

my $baz = Baz->new;
$baz->yell;
is( $observations[1], "Observation B from [Baz]", "Catch notification from child" );
is( $observations[2], "Observation A from [Baz]", "Catch parent notification from child" );
