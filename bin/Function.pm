#!/usr/bin/perl

package Function;

# +---------------+
# |  Constructor  |
# +---------------+
sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self;
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



# +-----------+
# |  Ze End!  |
# +-----------+
# -- Final line.  Must be a 'true' value.
1;
