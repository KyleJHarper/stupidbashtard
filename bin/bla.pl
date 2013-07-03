#!/usr/bin/perl

# +------------------+
# |  Pre-Requisites  |
# +------------------+
# -- Import required items.  This is done at compile time!
use strict ;
use warnings ;
use Getopt::Std ;
use Cwd 'abs_path' ;
use File::Basename ;
use lib dirname ( abs_path( __FILE__ ) ) ;
use Function ;



my $func;
my @lines;
$func = Function->new();
$func->variable_tags("SOME_VAR", "Text 1 for SOME_VAR");
$func->variable_tags("SOME_VAR", "Text 2 for SOME_VAR");
$func->variable_tags("OTHER_VAR", "Text for OTHER_VAR");

foreach ($func->variable_tags()) {
  foreach my $line (split /\n/, $func->variable_tags($_)) {
    print "      ${line}\n";
  }
}

exit 0;
