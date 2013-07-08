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
use Switch ;

my $OPT_CC       = '[:a-zA-Z0-9,]' ;  # Character class for getopts options
my $FIRST_VAR_CC = '[a-zA-Z_]'     ;  # Character class for first character of a variable
my $VAR_CC       = '[a-zA-Z0-9_]'  ;  # Character class for second and beyond characters of a variable
my $FUNC_CC      = '[a-zA-Z0-9_-]' ;  # Character class for function names
my $VERBOSE      = 'yep';
my @FLAGS;
my $NAME;
my $VALUE;
my $SCOPE;
my $FLAG_SWITCHES;

while(<>) {
  if ( /^[\s]*(([\s]*['"]?${OPT_CC}+['"]?[\s]*\|?)+)\)/ )  {
    print $1 . "\n" ;
  }
}



sub print_so_verbose {
  if ( $VERBOSE ) { print "@_\n" ; return 0 ; }
}

exit 0;
