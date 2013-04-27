#!/usr/bin/perl


# +------------------+
# |  Pre-Requisites  |
# +------------------+
# Import required items
use strict ;
use warnings ;
use Getopt::Std ;
use Cwd 'abs_path' ;
use File::Basename ;


# +-----------------------+
# |  Variables & Getopts  |
# +-----------------------+
my $LIB_DIR = dirname ( abs_path( __FILE__ ) ) . "/../lib" ;
my $QUIET   = "" ;

# +--------+
# |  Main  |
# +--------+
# -- Preflight Checks
if ( ! -d $LIB_DIR ) { die "error:  Cannot find lib dir and no specific files listed.  Aborting." ; }

# -- Read Ze Files
print "\n" ;


# +----------------+
# |  Sub-Routines  |
# +----------------+
sub usage {
  print
}

sub print_so {
  # This exists to print things to stdout, but respects the -q flag
  if ( $QUIET ) { return 0 ; }
}
