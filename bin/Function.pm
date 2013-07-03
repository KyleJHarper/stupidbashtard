#!/usr/bin/perl

package Function;

# +---------------+
# |  Constructor  |
# +---------------+
sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self;

  # Initialize empty strings for keys
  $self->{"YAML_SPACE"}    = "      ";
  $self->{"argument_tags"} = {};
  $self->{"basic_tags"}    = {};
    $self->{"basic_tags"}{"Author"}      = "";
    $self->{"basic_tags"}{"Date"}        = "";
    $self->{"basic_tags"}{"Description"} = "";
    $self->{"basic_tags"}{"Namespace"}   = "";
    $self->{"basic_tags"}{"Version"}     = "";
  $self->{"exit_tags"}     = {};
  $self->{"option_tags"}   = {};
  $self->{"variable_tags"} = {};

  # Set defaults if none provided
  if ( ! $self->{"name"} )           { $self->{"name"} = "" ; }
  if ( ! $self->{"openedbraces"} )   { $self->{"openedbraces"} = 0 ; }
  if ( ! $self->{"closedbraces"} )   { $self->{"closedbraces"} = 0 ; }

  # Return me
  return $self;
}


# +--------------+
# |  Properties  |
# +--------------+
# -- Name of the function
sub name {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"name"} = shift; }
  return $self->{"name"};
}

# -- Count of opened braces outside of any quotations
sub opened_braces {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"openedbraces"} = shift; }
  return $self->{"openedbraces"};
}

# -- Count of closed braces outside of any quotations
sub closed_braces {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"closedbraces"} = shift; }
  return $self->{"closedbraces"};
}

# -- Associative arrays of argument tags
sub argument_tags {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  if ( $key && $value ) { $self->{"argument_tags"}->{$key} .= $value . "\n" ; return 1 ; }
  if ( $key )           { return $self->{"argument_tags"}{$key} ; }
  return keys $self->{"argument_tags"};
}

# -- Associative arrays of basic tags
sub basic_tags {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  if ( $key && $value ) { $self->{"basic_tags"}->{$key} .= $value . "\n" ; return 1 ; }
  if ( $key )           { return $self->{"basic_tags"}{$key} ; }
  return keys $self->{"basic_tags"};
}

# -- Associative arrays of exit tags
sub exit_tags {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  if ( $key && $value ) { $self->{"exit_tags"}->{$key} .= $value . "\n" ; return 1 ; }
  if ( $key )           { return $self->{"exit_tags"}{$key} ; }
  return keys $self->{"exit_tags"};
}

# -- Associative arrays of option tags
sub option_tags {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  if ( $key && $value ) { $self->{"option_tags"}->{$key} .= $value . "\n" ; return 1 ; }
  if ( $key )           { return $self->{"option_tags"}{$key} ; }
  return keys $self->{"option_tags"};
}

# -- Associative arrays of variable tags
sub variable_tags {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  if ( $key && $value ) { $self->{"variable_tags"}->{$key} .= $value . "\n" ; return 1 ; }
  if ( $key )           { return $self->{"variable_tags"}{$key} ; }
  return keys $self->{"variable_tags"};
}


# +-----------------+
# |  Miscellaneous  |
# +-----------------+
sub count_braces {
  # Setup string and strip anything between quotes (braces inside quotes don't affect flow).
  my $self = shift ;
  my $line = shift ;
  $line =~ s/["][^"]*["]// ;
  $line =~ s/['][^']*[']// ;

  # Count braces and update properties
  my $opened = $line =~ tr/\{// ;
  my $closed = $line =~ tr/\}// ;
  $self->opened_braces( $self->opened_braces() + $opened );
  $self->closed_braces( $self->closed_braces() + $closed );

  # Report an error if the closed braces outnumber opened ones.  This should never happen.
  if ( $self->opened_braces() < $self->closed_braces() ) { return 0 ; }
  return 1;
}

sub braces_match {
  # This primarily checks for braces to be greater than zero and matching, to signify we're out of a function.
  my $self  = shift;
  if ( $self->opened_braces() >  $self->closed_braces() ) { return 0 ; }
  if ( $self->opened_braces() == 0 )                      { return 0 ; }
  if ( $self->opened_braces() == $self->closed_braces() ) { return 1 ; }
}

# +-----------+
# |  Ze End!  |
# +-----------+
# -- Final line.  Must be a 'true' value.
1;
