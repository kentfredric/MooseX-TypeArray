
use strict;
use warnings;

use Test::More;

use_ok('MooseX::TypeArray::Error');

my $instance = new_ok('MooseX::TypeArray::Error', [
  value => 5,
  name  => 'Foo',
  errors => {
    'Bar' => 'Bar iz 1',
    'Baz' => 'Baz iz 1',
  }
], 'error object','Create an instance' );

my $message = $instance->get_message;

note $instance->get_message;

like( $message, qr/Validation failed/ , 'Validation failed');
like( $message, qr/for 'Foo'/, 'For Foo');
like( $message, qr/\sBar:/, 'Shows Bar error');
like( $message, qr/\sBaz:/, 'Shows Baz error');

is( "" . $instance , $instance->get_message , "Instance stringifies to its message");
done_testing;



