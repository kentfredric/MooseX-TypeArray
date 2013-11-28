
use strict;
use warnings;

package Moose::Meta::TypeConstraint::TypeArray;

# ABSTRACT: Moose 'TypeArray' Base type constraint type.

use metaclass;

# use Moose::Meta::TypeCoercion::TypeArray;
use Moose::Meta::TypeConstraint;
use Try::Tiny;
use parent 'Moose::Meta::TypeConstraint';

__PACKAGE__->meta->add_attribute(
  'combining' => (
    accessor => 'combined_constraints',
    default  => sub { [] },
    Class::MOP::_definition_context(),
  )
);

__PACKAGE__->meta->add_attribute(
  'internal_name' => (
    accessor => 'internal_name',
    default  => sub { [] },
    Class::MOP::_definition_context(),
  )
);

__PACKAGE__->meta->add_attribute(
  '_default_message' => (
    accessor => '_default_message',
    Class::MOP::_definition_context(),
  )
);

my $_default_message_generator = sub {
  my ( $name, $constraints_ ) = @_;
  my (@constraints) = @{$constraints_};

  return sub {
    my $value = shift;
    require MooseX::TypeArray::Error;
    my %errors = ();
    for my $type (@constraints) {
      if ( my $error = $type->validate($value) ) {
        $errors{ $type->name } = $error;
      }
    }
    die MooseX::TypeArray::Error->new(
      name   => $name,
      value  => $value,
      errors => \%errors,
    );
  };
};

sub get_message {
  my ( $self, $value ) = @_;
  my $msg = $self->message || $self->_default_message;
  local $_ = $value;
  return $msg->($value);
}

sub new {
  my ( $class, %options ) = @_;

  my $name = 'TypeArray(' . ( join q{,}, sort { $a cmp $b } map { $_->name } @{ $options{combining} } ) . ')';

  my $self = $class->SUPER::new(
    name          => $name,
    internal_name => $name,

    %options,
  );
  $self->_default_message( $_default_message_generator->( $self->name, $self->combined_constraints ) )
    unless $self->has_message;

  return $self;
}

sub _actually_compile_type_constraint {
  my $self        = shift;
  my @constraints = @{ $self->combined_constraints };
  return sub {
    my $value = shift;
    foreach my $type (@constraints) {
      return if not $type->check($value);
    }
    return 1;
  };
}

sub validate {
  my ( $self, $value ) = @_;
  foreach my $type ( @{ $self->combined_constraints } ) {
    return $self->get_message($value) if defined $type->validate($value);
  }
  return;
}

1;
