use strict;
use warnings;

package MooseX::TypeArray;

# ABSTRACT: Create composite types where all subtypes must be satisfied

=head1 SYNOPSIS

  {
    package #
      Foo;
    use Moose::Util::TypeConstraint;
    use MooseX::TypeArray;
    subtype 'Natural',
      as 'Int',
      where { $_ > 0 };
      message { "This number ($_) is not bigger then 0" };

    subtype 'BiggerThanTen',
      as 'Int',
      where { $_ > 10 },
      message { "This number ($_) is not bigger than ten!" };


    typearray NaturalAndBiggerThanTen => [ 'Natural', 'BiggerThanTen' ];

    # or this , which is the same thing.

    typearray NaturalAndBiggerThanTen => {
      combining => [qw( Natural BiggerThanTen )],
    };


    ...

    has field => (
      isa => 'NaturalAndBiggerThanTen',
      ...
    );

    ...
  }
  use Try::Tiny;
  use Data::Dumper qw( Dumper );

  try {
    Foo->new( field => 0 );
  } catch {
    print Dumper( $_ );
    #
    # bless({  errors => {
    #   Natural => "This number (0) is not bigger then 0",
    #   BiggerThanTen => "This number (0) is not bigger than ten!"
    # }}, 'MooseX::TypeArray::Error' );
    #
    print $_;

    # Validation failed for TypeArray NaturalAndBiggerThanTen with value "0" :
    #   1. Validation failed for Natural:
    #       This number (0) is not bigger than 0
    #   2. Validation failed for BiggerThanTen:
    #       This number (0) is not bigger than ten!
    #
  }
=cut

use Sub::Exporter -setup => {
  exports => [qw( typearray )],
  groups  => [ default => [qw( typearray )] ],
};

sub _desugar_typearray {
  my (@args) = @_;
  my (@argtypes) = map { ref $_ ? ref $_ : '_string' } @args;
  my $signature = join q{,}, @argtypes;

  #  return {
  #    name      => undef,
  #    combining => []
  #  } if $signature eq '';

  return {
    name => undef,
    %{ $args[0] },
  } if $signature eq 'HASH';

  return {
    name      => undef,
    combining => $args[0],
  } if $signature eq 'ARRAY';

  # return { name => $args[0], } if $signature eq '_string';

  return {
    name      => $args[0],
    combining => $args[1],
  } if $signature eq '_string,ARRAY';

  return {
    name => $args[0],
    %{ $args[1] },
  } if $signature eq '_string,HASH';

  return {
    name => undef,
    %{ $args[1] },
    combining => [ @{ $args[1]->{combining} || [] }, @{ $args[0] } ],
    }
    if $signature eq 'ARRAY,HASH';

  return {
    name => $args[0],
    %{ $args[2] },
    combining => [ @{ $args[2]->{combining} || [] }, @{ $args[1] } ]
    }
    if $signature eq '_string,ARRAY,HASH';

  require Carp;
  Carp::confess( 'Unexpected parameters passed: "' . $signature . '"' );
}

sub _check_conflict_names {
  my ( $name, $package ) = @_;
  require Moose::Util::TypeConstraints;

  my $type = Moose::Util::TypeConstraints::find_type_constraint($name);

  if ( defined $type and $type->_package_defined_in eq $package ) {
    require Carp;
    Carp::confess( "The type constraint '$name' has already been created in "
        . $type->_package_defined_in
        . " and cannot be created again in $package " );
  }
  if ( $name !~ /^[\w:\.]+$/ ) {
    require Carp;
    Carp::confess(
      $name . qq{ contains invalid characters for a type name.} . qq{ Names can contain alphanumeric character, ":", and "."\n} );
  }
  return 1;
}

sub typearray {
  my $config = _desugar_typearray(@_);

  $config->{package_defined_in} = scalar( caller(0) );

  _check_conflict_names( $config->{name}, $config->{package_defined_in} ) if defined $config->{name};
  require Moose::Meta::TypeConstraint::TypeArray;
  my $constraint = Moose::Meta::TypeConstraint::TypeArray->new( %{$config} );

  if ( defined $config->{name} ) {
    require Moose::Util::TypeConstraints;
    Moose::Util::TypeConstraints::register_type_constraint($constraint);
  }

  return $constraint;

}

1;
