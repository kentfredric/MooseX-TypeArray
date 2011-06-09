
use strict;
use warnings;

package Example;
use Moose;
use Example::TypeLib;

has field => (
  isa      => 'NaturalAndBiggerThanTen',
  is       => 'rw',
  required => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

