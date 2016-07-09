use strict;
use warnings;
use Getopt::Std;

# Getopts
getopts('c:d:');
our($opt_c, $opt_d);
if (! $opt_c) { print STDERR "Character switch (-c) is compulsory, and missing apparently.  (aborting)\n" ;  exit 1 ; }
if (! $opt_d) { print STDERR "Direction switch (-d) is compulsory, and missing apparently.  (aborting)\n" ;  exit 1 ; }

# Search logic
while (<STDIN>) {
  if    ($opt_d eq 'left')  { s/^[${opt_c}]+//g ; print ; }
  elsif ($opt_d eq 'right') { s/[${opt_c}]+$//g ; print ; }
  elsif ($opt_d eq 'both')  { s/[${opt_c}]//g   ; print ; }
  else                      { print STDERR "Direction sent ($opt_d) isn't one of: right, left, both.  If called from SBT, should have been caught alredy.\n" ; exit 1; }
}
