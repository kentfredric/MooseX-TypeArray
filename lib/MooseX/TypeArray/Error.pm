use strict;
use warnings;

package MooseX::TypeArray::Error;

use Moose;
use Try::Tiny;

#use Class::Load;
use overload '""' => \&get_message;

#with 'StackTrace::Auto';

has 'name' => (
  isa      => 'Str',
  is       => 'rw',
  required => 1,
);

has 'value' => (
  is       => 'rw',
  required => 1,
);

has 'errors' => (
  isa      => 'HashRef',
  is       => 'rw',
  required => 1,
);

has 'message' => (
  isa       => 'CodeRef',
  is        => 'rw',
  predicate => 'has_message',
  traits    => ['Code'],
  handles   => { '_message' => 'execute', },
);

has '_stack_trace' => (
  is       => 'ro',
  isa      => 'CodeRef',
  builder  => '_build_stack_trace',
  init_arg => undef,
  required => 1,
  traits   => ['Code'],
  handles  => { 'stack_trace' => 'execute' },
);

sub _build_stack_trace {
  require Devel::StackTrace;
  my $found_mark = 0;
  my $uplevel    = 6;
  my $trace      = Devel::StackTrace->new(

    #    no_refs => 1,
    indent => 1,

    #    frame_filter => sub {
    #      my ($raw) = @_;
    #        if ($found_mark) {
    #         return 1 unless $uplevel;
    #        return !$uplevel--;
    #     }
    #     else {
    #       $found_mark = scalar $raw->{caller}->[3] =~ /new$/;
    #       return 0;
    #     }
    #   }
  );

  # this is to hide the guts of the stacktrace if you pass it to a dumper. Its far too bloaty.
  return sub { $trace };
}

sub get_message {
  my ($self) = @_;
  if ( $self->has_message ) {
    local $_ = $self->value;
    return $self->_message( $self, $_ );
  }
  my $value = $self->value;

  # Stolen liberally from Moose::Meta::TypeConstraint;

  # have to load it late like this, since it uses Moose itself
  my $can_partialdump = try {

    # versions prior to 0.14 had a potential infinite loop bug
    Class::MOP::load_class( 'Devel::PartialDump', { -version => 0.14 } );
    1;
  };
  if ($can_partialdump) {
    $value = Devel::PartialDump->new->dump($value);
  }
  else {
    $value = ( defined $value ? overload::StrVal($value) : 'undef' );
  }
  my @lines = ( 'Validation failed for \'' . $self->name . '\' with value ' . $value . ' :' );
  my $index = 0;
  push @lines, q{ -- };
  for my $suberror ( sort keys %{ $self->errors } ) {
    $index++;
    my $errorstr = "" . $self->errors->{$suberror};
    push @lines, ' ' . $index . '. ' . $suberror . ': ';
    push @lines, map { s/^/    /; $_ } split /\n/, $errorstr;
  }
  push @lines, q{ -- };
  push @lines, $self->stack_trace->as_string;
  return join qq{\n}, @lines;
}

1;

