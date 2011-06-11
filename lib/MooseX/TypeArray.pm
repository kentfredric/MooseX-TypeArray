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

my $sugarmap = {

  #  '' => sub {},
  'ARRAY' => sub { { name => undef, combining => $_[0], } },
  'HASH' => sub { { name => undef, %{ $_[0] }, combining => [ @{ $_[0]->{combining} || [] } ], } },

  #  '_string' => sub {},
  '_string,ARRAY' => sub { { name => $_[0], combining => $_[1], } },
  '_string,HASH' => sub { { name => $_[0], %{ $_[1] }, combining => [ @{ $_[1]->{combining} || [] } ], } },
  'ARRAY,HASH' => sub { { name => undef, %{ $_[1] }, combining => [ @{ $_[1]->{combining} || [] }, @{ $_[0] } ], } },
  '_string,ARRAY,HASH' => sub { { name => $_[0], %{ $_[2] }, combining => [ @{ $_[2]->{combining} || [] }, @{ $_[1] } ], } },

};

sub _desugar_typearray {
  my (@args) = @_;
  my (@argtypes) = map { ref $_ ? ref $_ : '_string' } @args;
  my $signature = join q{,}, @argtypes;

  if ( exists $sugarmap->{$signature} ) {
    return $sugarmap->{$signature}->(@args);
  }
  __PACKAGE__->_throw_error( 'Unexpected parameters types passed: <'
      . $signature . '>,' . qq{\n}
      . 'Expected one from [ '
      . ( join q{, }, map { '<' . $_ . '>' } sort keys %{$sugarmap} )
      . ' ] ' );
}

sub _check_conflict_names {
  my ( $name, $package ) = @_;
  require Moose::Util::TypeConstraints;

  my $type = Moose::Util::TypeConstraints::find_type_constraint($name);

  if ( defined $type and $type->_package_defined_in eq $package ) {
    __PACKAGE__->_throw_error( "The type constraint '$name' has already been created in "
        . $type->_package_defined_in
        . " and cannot be created again in $package " );
  }
  if ( $name !~ /^[\w:\.]+$/ ) {
    __PACKAGE__->_throw_error(
      $name . qq{ contains invalid characters for a type name.} . qq{ Names can contain alphanumeric character, ":", and "."\n} );
  }
  return 1;
}

sub _convert_type_names {
  my ( $name, @types ) = @_;
  require Moose::Util::TypeConstraints;
  my @out;
  for my $type (@types) {
    my $translated_type = Moose::Util::TypeConstraints::find_or_parse_type_constraint($type);
    if ( not $translated_type ) {
      __PACKAGE__->_throw_error("Could not locate type constraint ($type) for the TypeArray");
    }
    push @out, $translated_type;
  }
  return @out;
}

sub typearray {
  my $config = _desugar_typearray(@_);

  $config->{package_defined_in} = scalar( caller(0) );

  _check_conflict_names( $config->{name}, $config->{package_defined_in} ) if defined $config->{name};

  $config->{combining} = [ _convert_type_names( $config->{name}, @{ $config->{combining} } ) ];

  require Moose::Meta::TypeConstraint::TypeArray;

  my $constraint = Moose::Meta::TypeConstraint::TypeArray->new( %{$config} );

  if ( defined $config->{name} ) {
    require Moose::Util::TypeConstraints;
    Moose::Util::TypeConstraints::register_type_constraint($constraint);
  }

  return $constraint;

}

sub _throw_error {
  shift;
  require Moose;
  unshift @_, 'Moose';
  goto &Moose::throw_error;
}

1;
