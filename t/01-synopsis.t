use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib 't/01-lib';

use_ok('Example');

my $e = exception {
  Example->new( field => 0 );
};

isnt( $e, undef, '0 is not a valid value for a field' );
isa_ok( $e, 'MooseX::TypeArray::Error' );
can_ok( $e, 'errors', 'exception instance' );

my $errors;

is( exception { $errors = $e->errors }, undef, 'errors doesn\'t error itself' );
is( ref $errors, 'ARRAY', 'errors is an array' );

done_testing;

