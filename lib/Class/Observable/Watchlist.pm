package Class::Observable::Watchlist;

use strict;

my $cached_observable_parents = do {
	my %observable_parents;
	sub {
		my ( $class ) = @_;
		return $observable_parents{ $class }
			||= [ grep { $_->isa( 'Class::Observable' ) } Class::ISA::super_path( $class ) ];
	};
};

sub new {
	my $self = bless {}, shift;
	my ( $self_owner ) = @_;

	my $owner_class = ref( $self_owner ) || $self_owner;

	$self->{ watchlist } = [];
	$self->{ observable_parents } = $cached_observable_parents->( $owner_class );

	return $self;
}

sub add_observer {
	my $self = shift;
	return push @{ $self->{ watchlist } }, @_;
}

sub delete_observer {
	my $self = shift;

	my $watchlist = $self->{ watchlist };
	my $prev_num = @$watchlist;

	my %deletion_order;
	@deletion_order{ @_ } = ();

	@$watchlist = grep { not exists $deletion_order{ $_ } } @$watchlist;

	return $prev_num - @$watchlist;
}

sub delete_all_observers {
	my $self = shift;

	my $watchlist = $self->{ watchlist };
	my $prev_num = @$watchlist;

	@$watchlist = ();

	return $prev_num;
}

sub get_observers {
	my $self = shift;
	return @{ $self->{ watchlist } };
}

sub get_observable_parents {
	my $self = shift;
	return @{ $self->{ observable_parents } };
}

1;
