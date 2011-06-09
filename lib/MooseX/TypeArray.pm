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


    typearray NaturalAndBiggerThanTen => 'Natural', 'BiggerThanTen';

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

1;
