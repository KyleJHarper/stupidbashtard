#!/usr/bin/perl

package Test;

# +---------------+
# |  Constructor  |
# +---------------+
sub new {
  my $class = shift;
  my $self = { @_ };
  bless $self;

  # Return me
  return $self;
}


sub go_away {
  super(&fatal(1, "Ruh roh")) ;
}

# +-----------+
# |  Ze End!  |
# +-----------+
# -- Final line.  Must be a 'true' value.
1;
