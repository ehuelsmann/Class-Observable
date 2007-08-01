use strict;
use warnings;

package Class::Observable;

use Class::ISA;

for my $delegate ( qw(
	add_observer
	delete_observer
	delete_all_observers
) ) {
	my $sub = sub {
		my $self = shift;
		return $self->fetch_watchlist->$delegate( @_ );
	};
	no strict 'refs'; *{ $delegate } = $sub;
}

sub create_watchlist { Class::Observable::Watchlist->new }

*delete_observers = \&delete_all_observers;

sub get_direct_observers { shift->fetch_watchlist->get_observers }

{
	my %class_observer;
	sub fetch_watchlist {
		my $self = shift;
		ref $self ? $self->FETCH_WATCHLIST : ( $class_observer{ $self } ||= $self->create_watchlist );
	}
}

sub FETCH_WATCHLIST {
	my $self = shift;
	require Carp;
	Carp::croak(
		ref $self
			? "FETCH_WATCHLIST implementation missing in Observable '@{[ref $self]}'"
			: "Class::Observable::FETCH_WATCHLIST called"
	);
}

sub notify_observers {
	my $self = shift;
	my ( $action, @params ) = @_;
	$_->( $self, $action || '', @params ) for $self->get_observer_callables;
	return $self;
}

BEGIN {
	my $callable = sub {
		my ( $thing ) = @_;
		return ref $thing eq 'CODE' ? $thing : sub { $thing->receive_notification( @_ ) };
	};

	sub get_observer_callables { map { $callable->( $_ ) } shift->get_observers }
}

{
	my %observable_parents;

	sub get_observers {
		my $self = shift;

		my $class = ref( $self ) || $self;
		my $supers = $observable_parents{ $class } ||= [ grep { $_->isa( 'Class::Observable' ) } Class::ISA::super_path( $class ) ];

		my @observable_aspect = ref $self ? ( $self, $class, @$supers ) : ( $class, @$supers );

		my %seen;
		return (
			grep { not $seen{ $_ }++ }
			map  { $_->get_direct_observers }
			@observable_aspect
		);
	}
}

sub copy_observers_to {
	my $self = shift;
	my ( $target ) = @_;
	$target->add_observer( $self->get_observers );
	return $self;
}

sub copy_observers_from {
	my $self = shift;
	my ( $source ) = @_;
	$self->add_observer( $source->get_observers );
	return $self;
}

package Class::Observable::Watchlist;

sub new { bless [], shift }

sub add_observer {
	my $self = shift;
	push @$self, @_;
	return scalar @$self;
}

sub delete_observer {
	my $self = shift;
	my %deletion_order;
	undef @deletion_order{ @_ };
	my $prev_num = @$self;
	@$self = grep { not exists $deletion_order{ $_ } } @$self;
	return $prev_num - @$self;
}

sub delete_all_observers {
	my $self = shift;
	my $prev_num = @$self;
	@$self = ();
	return $prev_num;
}

sub get_observers {
	my $self = shift;
	return @$self;
}

1;

__END__

=head1 SYNOPSIS

  # Define an observable class
 
  package My::Object;
 
  use base qw( Class::Observable );
 
  # Tell all classes/objects observing this object that a state-change
  # has occurred
 
  sub create {
      my $self = shift;
      eval { $self->_perform_create() };
      if ( $@ ) {
          My::Exception->throw( "Error saving: $@" );
      }
      $self->notify_observers();
  }
 
  # Same thing, except make the type of change explicit and pass
  # arguments.
 
  sub edit {
      my $self = shift;
      my %old_values = $self->extract_values;
      eval { $self->_perform_edit() };
      if ( $@ ) {
          My::Exception->throw( "Error saving: $@" );
      }
      $self->notify_observers( 'edit', old_values => \%old_values );
  }
 
  # Define an observer
 
  package My::Observer;
 
  sub receive_notification {
      my $class = shift;
      my ( $object, $action ) = @_;
      unless ( $action ) {
          warn "Cannot operation on [", $object->id, "] without action";
          return;
      }
      $class->_on_save( $object )   if ( $action eq 'save' );
      $class->_on_update( $object ) if ( $action eq 'update' );
  }
 
  # Register the observer class with all instances of the observable
  # class
 
  My::Object->add_observer( 'My::Observer' );
 
  # Register the observer class with a single instance of the
  # observable class
 
  my $object = My::Object->new( 'foo' );
  $object->add_observer( 'My::Observer' );
 
  # Register an observer object the same way
 
  my $observer = My::Observer->new( 'bar' );
  My::Object->add_observer( $observer );
  my $object = My::Object->new( 'foo' );
  $object->add_observer( $observer );
 
  # Register an observer using a subroutine
 
  sub catch_observation { ... }
 
  My::Object->add_observer( \&catch_observation );
  my $object = My::Object->new( 'foo' );
  $object->add_observer( \&catch_observation );
 
  # Define the observable class as a parent and allow the observers to
  # be used by the child
 
  package My::Parent;
 
  use strict;
  use base qw( Class::Observable );
 
  sub prepare_for_bed {
      my $self = shift;
      $self->notify_observers( 'prepare_for_bed' );
  }
 
  sub brush_teeth {
      my $self = shift;
      $self->_brush_teeth( time => 45 );
      $self->_floss_teeth( time => 30 );
      $self->_gargle( time => 30 );
  }
 
  sub wash_face { ... }
 
 
  package My::Child;
 
  use strict;
  use base qw( My::Parent );
 
  sub brush_teeth {
      my $self = shift;
      $self->_wet_toothbrush();
  }
 
  sub wash_face { return }
 
  # Create a class-based observer
 
  package My::ParentRules;
 
  sub receive_notification {
      my $self = shift;
      my ( $action ) = @_;
      if ( $action eq 'prepare_for_bed' ) {
          $self->brush_teeth;
          $self->wash_face;
      }
  }
 
  My::Parent->add_observer( __PACKAGE__ );
 
  $parent->prepare_for_bed # brush, floss, gargle, and wash face
  $child->prepare_for_bed  # pretend to brush, pretend to wash face

=head1 DESCRIPTION

If you have ever used Java, you may have run across the
C<java.util.Observable> class and the C<java.util.Observer>
interface. With them you can decouple an object from the one or more
objects that wish to be notified whenever particular events occur.

These events occur based on a contract with the observed item. They
may occur at the beginning, in the middle or end of a method. In
addition, the object B<knows> that it is being observed. It just does
not know how many or what types of objects are doing the observing. It
can therefore control when the messages get sent to the obsevers.

The behavior of the observers is up to you. However, be aware that we
do not do any error handling from calls to the observers. If an
observer throws a C<die>, it will bubble up to the observed item and
require handling there. So be careful.

Throughout this documentation we refer to an 'observed item' or
'observable item'. This ambiguity refers to the fact that both a class
and an object can be observed. The behavior when notifying observers
is identical. The only difference comes in which observers are
notified. (See L<Observable Classes and Objects> for more
information.)

=head2 Observable Classes and Objects

The observable item does not need to implement any extra methods or
variables. Whenever it wants to let observers know about a
state-change or occurrence in the object, it just needs to call
C<notify_observers()>.

As noted above, whether the observed item is a class or object does
not matter -- the behavior is the same. The difference comes in
determining which observers are to be notified:

=over 4

=item *

If the observed item is a class, all objects instantiated from that
class will use these observers. In addition, all subclasses and
objects instantiated from the subclasses will use these observers.

=item *

If the observed item is an object, only that particular object will
use its observers. Once it falls out of scope then the observers will
no longer be available. (See L<Observable Objects and DESTROY> below.)

=back

Whichever you chose, your documentation should make clear which type
of observed item observers can expect.

So given the following example:

 BEGIN {
     package Foo;
     use base qw( Class::Observable );
     sub new { return bless( {}, $_[0] ) }
     sub yodel { $_[0]->notify_observers }
 
     package Baz;
     use base qw( Foo );
     sub yell { $_[0]->notify_observers }
 }
 
 sub observer_a { print "Observation A from [$_[0]]\n" }
 sub observer_b { print "Observation B from [$_[0]]\n" }
 sub observer_c { print "Observation C from [$_[0]]\n" }
 
 Foo->add_observer( \&observer_a );
 Baz->add_observer( \&observer_b );
 
 my $foo = Foo->new;
 print "Yodeling...\n";
 $foo->yodel;
 
 my $baz_a = Baz->new;
 print "Yelling A...\n";
 $baz_a->yell;
 
 my $baz_b = Baz->new;
 $baz_b->add_observer( \&observer_c );
 print "Yelling B...\n";
 $baz_b->yell;

You would see something like

 Yodeling...
 Observation A from [Foo=HASH(0x80f7acc)]
 Yelling A...
 Observation B from [Baz=HASH(0x815c2b4)]
 Observation A from [Baz=HASH(0x815c2b4)]
 Yelling B...
 Observation C from [Baz=HASH(0x815c344)]
 Observation B from [Baz=HASH(0x815c344)]
 Observation A from [Baz=HASH(0x815c344)]

And since C<Bar> is a child of C<Foo> and each has one class-level
observer, running either:

 my @observers = Baz->get_observers();
 my @observers = $baz_a->get_observers();

would return a two-item list. The first item would be the
C<observer_b> code reference, the second the C<observer_a> code
reference. Running:

 my @observers = $baz_b->get_observers();

would return a three-item list, including the observer for that
specific object (C<observer_c> coderef) as well as from its class
(Baz) and the parent (Foo) of its class.

=head2 Observers

There are three types of observers: classes, objects, and
subroutines. All three respond to events when C<notify_observers()> is
called from an observable item. The differences among the three are
are:

=over 4

=item *

A class or object observer must implement a method C<receive_notification()> which
is called when a state-change occurs. The name of the subroutine
observer is irrelevant.

=item *

A class or object observer must take at least two arguments: itself
and the observed item. The subroutine observer is obligated to take
only one argument, the observed item.

Both types of observers may also take an action name and a hashref of
parameters as optional arguments. Whether these are used depends on
the observed item.

=item *

Object observers can maintain state between responding to
observations.

=back

Examples:

B<Subroutine observer>:

 sub respond {
     my ( $item, $action, $params ) = @_;
     return unless ( $action eq 'update' );
     # ...
 }
 $observable->add_observer( \&respond );

B<Class observer>:

 package My::ObserverC;
 
 sub receive_notification {
     my ( $class, $item, $action, $params ) = @_;
     return unless ( $action eq 'update' );
     # ...
 }

B<Object observer>:

 package My::ObserverO;
 
 sub new {
     my ( $class, $type ) = @_;
     return bless ( { type => $type }, $class );
 }
 
 sub receive_notification {
     my ( $self, $item, $action, $params ) = @_;
     return unless ( $action eq $self->{type} );
     # ...
 }

=head1 METHODS

=head2 Observed Item Methods

B<notify_observers( [ $action, @params ] )>

Called from the observed item, this method sends a message to all
observers that a state-change has occurred. The observed item can
optionally include additional information about the type of change
that has occurred and any additional parameters C<@params> which get
passed along to each observer. The observed item should indicate in
its API what information will be passed along to the observers in
C<$action> and C<@params>.

Returns: Nothing

Example:

 sub remove {
     my ( $self ) = @_;
     eval { $self->_remove_item_from_datastore };
     if ( $@ ) {
         $self->notify_observers( 'remove-fail', error_message => $@ );
     }
     else {
         $self->notify_observers( 'remove' );
     }
 }

B<add_observer( @observers )>

Adds the one or more observers (C<@observer>) to the observed
item. Each observer can be a class name, object or subroutine -- see
L<Types of Observers>.

Returns: The number of observers now observing the item.

Example:

 # Add a salary check (as a subroutine observer) for a particular
 # person
 my $person = Person->fetch( 3843857 );
 $person->add_observer( \&salary_check );
 
 # Add a salary check (as a class observer) for all people
 Person->add_observer( 'Validate::Salary' );
 
 # Add a salary check (as an object observer) for all people
 my $salary_policy = Company::Policy::Salary->new( 'pretax' );
 Person->add_observer( $salary_policy );

B<delete_observer( @observers )>

Removes the one or more observers (C<@observer>) from the observed
item. Each observer can be a class name, object or subroutine -- see
L<Types of Observers>.

Note that this only deletes each observer from the observed item
itself. It does not remove observer from any parent
classes. Therefore, if an observer is not registered directly with the
observed item nothing will be removed.

Returns: The number of observers now observing the item.

Examples:

 # Remove a class observer from an object
 $person->delete_observer( 'Lech::Ogler' );
 
 # Remove an object observer from a class
 Person->delete_observer( $salary_policy );

B<delete_all_observers()>

Removes all observers from the observed item.

Note that this only deletes observers registered directly with the
observed item. It does not clear out observers from any parent
classes.

B<WARNING>: This method was renamed from C<delete_observers>. The
C<delete_observers> call still works but is deprecated and will
eventually be removed.

Returns: The number of observers removed.

Example:

 Person->delete_all_observers();

B<get_observers()>

Returns all observers for an observed item, as well as the observers
for its class and parents as applicable. See L<Observable Classes and
Objects> for more information.

Returns: list of observers.

Example:

 my @observers = Person->get_observers;
 foreach my $o ( @observers ) {
     print "Observer is a: ";
     print "Class"      unless ( ref $o );
     print "Subroutine" if ( ref $o eq 'CODE' );
     print "Object"     if ( ref $o and ref $o ne 'CODE' );
     print "\n";
 }

B<copy_observers( $copy_to_observable )>

Copies all observers from one observed item to another. We get all
observers from the source, including the observers of parents. (Behind
the scenes we just use C<get_observers()>, so read that for what we
copy.)

We make no effort to ensure we don't copy an observer that's already
watching the object we're copying to. If this happens you will appear
to get duplicate observations. (But it shouldn't happen often, if
ever.)

Returns: number of observers copied

Example:

 # Copy all observers of the 'Person' class to also observe the
 # 'Address' class
 
 Person->copy_observers( Address );
 
 # Copy all observers of a $person to also observe a particular
 # $address
 
 $person->copy_observers( $address )

B<count_observers()>

Counts the number of observers for an observed item, including ones
inherited from its class and/or parent classes. See L<Observable
Classes and Objects> for more information.

=head1 RESOURCES

APIs for C<java.util.Observable> and C<java.util.Observer>. (Docs
below are included with JDK 1.4 but have been consistent for some
time.)

L<http://java.sun.com/j2se/1.4/docs/api/java/util/Observable.html>

L<http://java.sun.com/j2se/1.4/docs/api/java/util/Observer.html>

"Observer and Observable", Todd Sundsted,
L<http://www.javaworld.com/javaworld/jw-10-1996/jw-10-howto_p.html>

"Java Tip 29: How to decouple the Observer/Observable object model", Albert Lopez,
L<http://www.javaworld.com/javatips/jw-javatip29_p.html>

=head1 SEE ALSO

L<Class::ISA|Class::ISA>

L<Class::Trigger|Class::Trigger>

L<Aspect|Aspect>
