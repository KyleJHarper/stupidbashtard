# Modules
use warnings;
use strict;
use Getopt::Std;

# Getopts
getopts('f:');
our($opt_f);

# Search logic
my $count=0;
while (<>) {
  while ($_ =~ m/($opt_f)/g) {
    $count++
  }
}
print $count

