#!/usr/bin/perl

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


package Function;

# +---------------+
# |  Constructor  |
# +---------------+
sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self;

  # Initialize empty strings for keys
  $self->{'argument_tags'}   = {};
  $self->{'basic_tags'}      = {};
  $self->{'dependency_tags'} = {};
  $self->{'options'}         = {};
  $self->{'option_tags'}     = {};
  $self->{'variables'}       = {};
  $self->{'variable_tags'}   = {};

  # Set defaults if none provided
  if ( ! $self->{'closedbraces'}    ) { $self->{'closedbraces'}    = 0       ; }
  if ( ! $self->{'indirect_output'} ) { $self->{'indirect_output'} = 'false' ; }
  if ( ! $self->{'name'}            ) { $self->{'name'}            = ''      ; }
  if ( ! $self->{'openedbraces'}    ) { $self->{'openedbraces'}    = 0       ; }
  if ( ! $self->{'required_tools'}  ) { $self->{'required_tools'}  = ''      ; }
  if ( ! $self->{'thread_safe'}     ) { $self->{'thread_safe'}     = 'true'  ; }
  if ( ! $self->{'loop_level'}      ) { $self->{'loop_level'}      = 0       ; }

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

# -- Indirect Output flag
sub indirect_output {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"indirect_output"} = shift; }
  return $self->{"indirect_output"};
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

# -- Loop Level
sub loop_level {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"loop_level"} = shift; }
  return $self->{"loop_level"};
}

# -- Thread Safety
sub thread_safe {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"thread_safe"} = shift; }
  return $self->{"thread_safe"};
}

# -- Tools required for the function.  A simple comma-separated list is fine.
sub tools {
  my $self = shift;
  my $tool = shift;
  if ( $tool ) { $self->{"required_tools"} .= $tool . ',' ; }
  return $self->{"required_tools"};
}

# -- Tags
sub tags {
  my $self  = shift;
  my $root  = shift;
  my $key   = shift;
  my $value = shift;
  $root    .= "_tags";
  chomp $value;

  # Set a value if specified.
  if ( $key && $value ) { $self->{$root}->{$key} .= $value =~ s/^-//r . "\n"; return 1 ; }

  # Return a value if a key has been provided.
  if ( $key ) { return $self->{$root}->{$key} ; }

  # Return keys of the root if no key or value was sent.
  return keys $self->{$root};
}

# -- Options
sub options {
  my $self  = shift;
  my $opt   = shift;
  my $value = shift;
  chomp $value;

  # Set a value if specified.
  if ( $opt && $value ) { $self->{'options'}->{$opt} = $value ; return 1 ; }

  # Return a value if a key has been provided.
  if ( $opt ) { return $self->{'options'}->{$opt} ; }

  # Return keys of the root if no key or value was sent.
  return keys $self->{'options'};
}

# -- Variables
sub variables {
  my $self     = shift;
  my $variable = shift;
  my $property = shift;
  my $value    = shift;
  chomp $value;

  # Setup anonymous hash if it hasn't been created yet.
  if ( $variable ) {
    if ( ! $self->{'variables'}->{$variable} ) { $self->{'variables'}{$variable} = {} ; }
  }

  # Set a value if value, variable name, and property specified.
  if ( $variable && $property && $value ) { $self->{'variables'}->{$variable}->{$property} = $value ; return 1 ; }

  # Return a value if only a variable name and property were sent.
  if ( $variable && $property ) { return $self->{'variables'}->{$variable}->{$property} ; }

  # Return keys (properties) of the variable specified, if only variable specified.
  if ( $variable ) { return keys $self->{'variables'}->{$variable} ; }

  # Return keys (variable names) if nothing was sent.
  return keys %{$self->{'variables'}};
}


# +-----------------+
# |  Miscellaneous  |
# +-----------------+
sub count_braces {
  # Setup string and strip anything between quotes (braces inside quotes don't affect flow).
  my $self = shift ;
  my $line = shift ;
  $line =~ s/["][^"]*["]//g ;
  $line =~ s/['][^']*[']//g ;

  # Count braces and update properties
  my $opened = $line =~ tr/\{// ;
  my $closed = $line =~ tr/\}// ;
  $self->opened_braces( $self->opened_braces() + $opened );
  $self->closed_braces( $self->closed_braces() + $closed );

  # Caller must check if braces don't match.
  return 1;
}

sub count_loops {
  # Setup string and strip anything between quotes (for/while/until/done inside quotes don't affect flow).
  my $self = shift ;
  my $line = shift ;
  $line =~ s/["][^"]*["]//g ;
  $line =~ s/['][^']*[']//g ;

  # Count for|while|until and update properties.
  my $start = $line =~ tr/(while|until|for)[\s]+// ;
  my $end   = $line =~ tr/(;[\s]*)?done// ;
  $self->loop_level( $self->loop_level() + $start - $end );

  # Caller must check if loop level meets certain conditions... like going negative.
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
