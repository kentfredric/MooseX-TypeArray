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

use Moose::Util::TypeConstraints ();

sub typearray {
  my ( $name, @rest ) = @_;
  my ($config) = {};
  if ( ref $rest[-1] eq 'HASH' ) {
    $config = pop @rest;
  }
  $config->{combining} = [] if not exists $config->{combining};
  push @{ $config->{combining} }, @rest;

  my $pkg_defined_in = scalar( caller(0) );

  if ( defined $name ) {

    my $type = Moose::Util::TypeConstraints::get_type_constraint($name);

    if ( defined $type and $type->_package_defined_in eq $pkg_defined_in ) {
      require Carp;
      Carp::confess( "The type constraint '$name' has already been created in "
          . $type->_package_defined_in
          . " and cannot be created again in "
          . $pkg_defined_in );
    }

    if ( $name =~ /^[\w:\.]+$/ ) {
      require Carp;
      Carp::confess(
        qq{$name contains invalid characters for a type name.} . qq{ Names can contain alphanumeric character, ":", and "."\n} );
    }
  }

  my %opts = (
    name               => $name,
    package_defined_in => $pkg_defined_in,
#    ( $check     ? ( constraint => $check )     : () ),
    ( $message   ? ( message    => $message )   : () ),
#    ( $optimized ? ( optimized  => $optimized ) : () ),
  );
}
1;
