use strict;
use warnings;

package Class::Observable;

use Class::Observable::Watchlist;
use Class::ISA;

my $get_watchlist = do {
	my %class_observer;

	sub {
		my $self = shift;
		return ref $self
			? $self->INSTANCE_WATCHLIST
			: $class_observer{ $self } ||= $self->create_watchlist;
	};
};

sub create_watchlist { Class::Observable::Watchlist->new( shift ) }

sub INSTANCE_WATCHLIST {
	my $self = shift;

	return $self->{ '::Class::Observable::watchlist_instance::' } ||= $self->create_watchlist
		if eval { %$self };  # if $self quacks like a hash
	
	my $self_class = ref $self;

	my $error = $self_class
		? "Observable '$self_class' is not a hash-based object; implement INSTANCE_WATCHLIST"
		: "Called INSTANCE_WATCHLIST as a class method on '$self'";

	require Carp;
	Carp::croak( $error );
}

sub notify_observers {
	my $self = shift;
	my $action = shift;

	$action = '' unless defined $action;

	for my $observer ( $self->get_observers ) {
		ref $observer eq 'CODE'
			? $observer->( $self, $action, @_ )
			: $observer->receive_notification( $self, $action, @_ );
	}

	return $self;
}

sub get_observers {
	my $self = shift;
	my $watchlist = $self->$get_watchlist;

	my @observer = $watchlist->list;
	if ( my $class = ref $self ) { push @observer, $class->$get_watchlist->list; }
	push @observer, map { $_->$get_watchlist->list } $watchlist->get_observable_parents;

	return do { my %seen; grep { not $seen{ $_ }++ } @observer };
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

sub get_direct_observers    { my $self = shift; return $self->$get_watchlist->list }
sub add_observer            { my $self = shift; $self->$get_watchlist->add( @_ ); return $self }
sub delete_observer         { my $self = shift; $self->$get_watchlist->delete( @_ ); return $self }
sub delete_direct_observers { my $self = shift; $self->$get_watchlist->clear(); return $self }

1;

__END__

=head1 SYNOPSIS

 # the author is a buffoon and forgot the synopsis code

=head1 DESCRIPTION

This class implements a simple universal event notification interface for
objects and classes. Observers are registered with observables; observables
simply announce events without knowing their observers.

Observables can be either classes or instances. If an observer is registered
with a class, it will receive notifications from all objects instanciated from
that class or one of its subclasses. If it is registered with an instance, only
the events announced by that instance will be relayed to it.

=head1 OBSERVER INTERFACE

An observer is either a code reference, or a class or object. Code references
are invoked directly. Classes and objects must respond to the
C<receive_notification> method.

The first parameter passed to the observer is the observable that is sending
the notification. Further parameters depend on the observable.

=head1 METHODS

=head2 C<notify_observers( @param )>

Called from the observed item to notify observers of an event. Any parameters
are optional. They will be passed to all observers. When given, the second
parameter should commonly be an event name; likewise the third would commonly
be a hash reference with further information. However, this is only a
convention; make sure to document your event parameters.

 sub remove {
     my ( $self ) = @_;
     eval { $self->_remove_item_from_datastore };
     if ( $@ ) {
         $self->notify_observers( 'remove-fail', { error_message => $@ } );
     }
     else {
         $self->notify_observers( 'remove' );
     }
 }

Observers will be notified I<exactly once>. If a particular observer happens to
be registered with several of the observable classes in the inheritance chain
and/or also the observable instance, it I<will not> be notified multiple times.

No implicit exception handling is done when observers are notified. If an
observer C<die>s, the exception will bubble up to the caller if
C<notify_observers> and require handling there. So be careful.

=head2 C<add_observer( @observer )>

Adds one or more observers to the observable. Each observer can be a class
name, object or subroutine.

The observable will hold onto its observers. If you need them garbage-collected
before the observable goes out of scope, you will have to explicitly remove
them from the observable. Of course, if the observable is an instance, it may
itself be garbage-collected (eg. when it falls out of scope with no other
references around), in which case it will let go of its observers. For the most
part, things should Just Work as you expect them, but be careful when you add
observers to classes, because barring manual intervention, they will stick
around forever.

=head2 C<delete_observer( @observers )>

Removes one or more given observers from the observed item. Each observer can
be a class name, object or subroutine.

Note that this only deletes each observer from the observed item itself. It
does not remove observers from any parent classes. Therefore, if an observer is
not registered directly with the observed item it will not be removed.

=head2 C<delete_direct_observers()>

Removes from an observable all observers that are registered with it directly.
Observers from superclasses will not be removed, and if the observable is an
instance, observers on its class will not be removed.

=head2 C<get_observers()>

Returns all observers for an observable. This is the exact list of observers
that would be notified when C<notify_observers> is called and includes
observers on all superclass as well as the class of an instance.

=head2 C<copy_observers_to( $destination_observable )>

Copies all observers from one observable to another. This means literally
B<all> of the observers -- including class observers!

B<Watch out!> If you do the following, you may be surprised by its behaviour:

 # add an observer to the class
 Some::Observable->add_observer( 'Observer::One' );
 
 # make two instances of the class
 my $obj1 = Some::Observable->new;
 my $obj2 = Some::Observable->new;
 
 # add an object observer to one of them...
 $obj1->add_observer( 'Observer::Two' );

 # eh, we'll be lazy and copy to get the
 # observers onto the second one
 $obj1->copy_observers_to( $obj2 );
 
 # and now we remove the observer from the class
 Some::Observable->delete_observer( 'Observer::One' );

Hereafter, C<$obj1> and other instances of C<Some::Observable> will no longer
notify C<Observer::One> of events, B<but C<$obj2> will continue to do so>!

XXX THIS IS A BUG XXX

TODO Move away from the implementation in terms of get_observers to one that
retrieves direct observers and the observers of each superclass separately,
so it can make sure not to copy class observers from common superclasses.

=head2 C<copy_observers_from( $source_observable )>

Same as
L<C<copy_observers_to>|copy_observers_to( $destination_observable )>, but in
the reverse direction. B<All of the same caveats apply>; make sure to read
about them there.

=head1 SEE ALSO

=over 4

=item *

L<Class::Trigger|Class::Trigger>

=item *

L<Aspect|Aspect>
