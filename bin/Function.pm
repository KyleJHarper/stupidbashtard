#!/usr/bin/perl

package Function;

# +---------------+
# |  Constructor  |
# +---------------+
sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self;

  # Set defaults if none provided
  if ( ! $self->{"name"} )           { $self->{"name"} = "" ; }
  if ( ! $self->{"openedbraces"} )   { $self->{"openedbraces"} = 0 ; }
  if ( ! $self->{"closedbraces"} )   { $self->{"closedbraces"} = 0 ; }
  if ( ! $self->{"ready_to_leave"} ) { $self->{"ready_to_leave"} = "" ; }

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

sub opened_braces {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"openedbraces"} = shift; }
  return $self->{"openedbraces"};
}

sub closed_braces {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"closedbraces"} = shift; }
  return $self->{"closedbraces"};
}

sub ready_to_leave {
  my $self = shift;
  if ( scalar(@_) == 1) { $self->{"ready_to_leave"} = shift; }
  return $self->{"ready_to_leave"};
}

sub tags {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  if ( $key && $value ) { $self->{"tags"}{$key} = $self->{"tags"}{$key} . $value ; return 1 ; }
  if ( $key )           { return $self->{"tags"}{$key} ; }
  return keys $self->{"tags"};
}


# +-----------+
# |  Ze End!  |
# +-----------+
# -- Final line.  Must be a 'true' value.
1;
