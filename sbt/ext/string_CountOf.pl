# Modules
use warnings;
use strict;
use Getopt::Std;

# Getopts
getopts('p:');
our($opt_p);
$opt_p || exit 1;

# Search logic
my $count=0;
while (<STDIN>) {
  chomp if eof; #Count will be off by one for newline patterns if we don't do this.  Might cause other edge cases.
  while ($_ =~ m/($opt_p)/g) {
    $count++
  }
}

print $count

