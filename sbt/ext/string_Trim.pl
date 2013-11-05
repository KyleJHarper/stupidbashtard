use strict;
use warnings;
use Getopt::Std;

# Getopts
getopts('c:d:');
our($opt_c, $opt_d);
$opt_c || exit 1;
$opt_d || exit 1;

# Search logic
while (<STDIN>) {
  if    ($opt_d == 'left')  { s/^${opt_c}+//g ; print ; }
  elsif ($opt_d == 'right') { s/${opt_c}+$//g ; print ; }
  elsif ($opt_d == 'both')  { s/${opt_c}//g   ; print ; }
  else                      { exit 1; }
}
