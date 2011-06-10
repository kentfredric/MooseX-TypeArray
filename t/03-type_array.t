
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use_ok('MooseX::TypeArray');

can_ok( 'MooseX::TypeArray', qw( _desugar_typearray _check_conflict_names typearray import ) );

sub fmt_exception {
  my ( $e ) = shift;
  my ( @lines ) = split qr|$/|, $e;
  return explain { exception => \@lines };
}
sub x_test {
  my ( $input, $expected, $name ) = @_;
  my $exception;
  is(
    $exception = exception {
      is_deeply( MooseX::TypeArray::_desugar_typearray( @{$input} ), $expected, $name );
    },
    undef,
    "$name <- does not throw()"
  );
  return $exception;
}

sub xf_test {
  my ( $input, $expected, $name ) = @_;
  my $exception;
  isnt(
    $exception = exception {
      is_deeply( MooseX::TypeArray::_desugar_typearray( @{$input} ), $expected, $name );
    },
    undef,
    "$name <- throws()"
  );
  return $exception;
}

note fmt_exception xf_test( [], undef, 'no parameters are bad!' );
x_test( [ {} ], { name => undef, combining => [] }, 'Hashref is mostly passthrough' );
x_test( [ [] ], { name => undef, combining => [] }, 'Arrayref is anon-sugar' );
note fmt_exception xf_test( ['example'], undef, 'only name is bad!' );
x_test( [ 'example', [] ], { name => 'example', combining => [] }, '"name, [ ]"  form' );
x_test( [ 'example', {} ], { name => 'example', combining => [] }, '"name, {}"  form' );
note fmt_exception xf_test( [ [], [] ], { name => 'example', combining => [] }, '"[], []"  is bad' );
note fmt_exception xf_test( [ {}, {} ], { name => 'example', combining => [] }, '"{}, {}"  is bad' );

x_test( [ 'example', {} ], { name => 'example', combining => [] }, '"name, {}"  form' );


done_testing;

