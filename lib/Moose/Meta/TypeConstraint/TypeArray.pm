
use strict;
use warnings;

package Moose::Meta::TypeConstraint::TypeArray;

use metaclass;

# use Moose::Meta::TypeCoercion::TypeArray;
use Moose::Meta::TypeConstraint;
use parent 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute(
  'combining' => (
    accessor => 'combined_constraints',
    default  => sub { [] },
  )
);

__PACKAGE__->meta->add_attribute(
  'internal_name' => (
    accessor => 'internal_name',
    default  => sub { [] },
  )
);

sub new {
  my ( $class, %options ) = @_;

  my $name = 'TypeArray('
    . (
    join ',' => sort { $a cmp $b }
      map { $_->name } @{ $options{combining} }
    ) . ')';

  my $self = $class->SUPER::new(
    name => $name,
    internal_name => $name,
    %options,
  );

  return $self;
}

sub validate {
  my ( $self, $value ) = @_;
  my @errors;
  foreach my $type ( @{ $self->combined_constraints } ) {
    my $err = $type->validate( $value );
    push @errors, $err if defined $err;
  }
  return undef unless @errors;
  return '[ ' . (join ',' , @errors ) .  ' ]';
}

1;
