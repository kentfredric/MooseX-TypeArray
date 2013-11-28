
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.4203"
  },
  "configure_requires" => {
    "Module::Build" => "0.4203"
  },
  "dist_abstract" => "Create composite types where all subtypes must be satisfied",
  "dist_author" => [
    "Kent Fredric <kentnl\@cpan.org>"
  ],
  "dist_name" => "MooseX-TypeArray",
  "dist_version" => "0.1.1",
  "license" => "perl",
  "module_name" => "MooseX::TypeArray",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Devel::StackTrace" => 0,
    "Module::Runtime" => 0,
    "Moose" => 0,
    "Moose::Meta::TypeConstraint" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "Sub::Exporter" => 0,
    "Try::Tiny" => 0,
    "metaclass" => 0,
    "overload" => 0,
    "parent" => 0,
    "perl" => "v5.10.0",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "MooseX::Attribute::ValidateWithException" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "1.001002",
    "lib" => 0
  }
);


my %fallback_build_requires = (
  "Module::Build" => "0.4203",
  "MooseX::Attribute::ValidateWithException" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "1.001002",
  "lib" => 0
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  delete $module_build_args{test_requires};
  $module_build_args{build_requires} = \%fallback_build_requires;
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
