package Class::Observable::Watchlist;

use strict;

sub new {
	my $self = bless {}, shift;
	my ( $self_owner ) = @_;

	%$self = (
		watchlist   => [],
		owner_class => ref( $self_owner ) || $self_owner,
	);

	return $self;
}

sub add {
	my $self = shift;
	return push @{ $self->{ watchlist } }, @_;
}

sub delete {
	my $self = shift;

	my $watchlist = $self->{ watchlist };
	my $prev_num = @$watchlist;

	my %deletion_order;
	@deletion_order{ @_ } = ();

	@$watchlist = grep { not exists $deletion_order{ $_ } } @$watchlist;

	return $prev_num - @$watchlist;
}

sub clear {
	my $self = shift;

	my $watchlist = $self->{ watchlist };
	my $prev_num = @$watchlist;

	@$watchlist = ();

	return $prev_num;
}

sub list {
	my $self = shift;
	return @{ $self->{ watchlist } };
}

{
	my %observable_parents;

	sub get_observable_parents {
		my $self = shift;
		my $class = $self->{ owner_class };

		my $parents = $observable_parents{ $class }
			||= [ grep { $_->isa( 'Class::Observable' ) } Class::ISA::super_path( $class ) ];

		return @$parents[ 0 .. $#$parents ];
	}
}

1;
