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
# -- Variable Initialization
my $E_GENERIC = 1 ;
my $LIB_DIR   = dirname ( abs_path( __FILE__ ) ) . "/../lib" ;
my $QUIET     = "" ;
my $VERBOSE   = "" ;

# -- GetOpts Overrides
getopts('qv') or &usage ;
our ($opt_q, $opt_v) ;
if ( defined $opt_q ) { $QUIET   = "Yep" ; }
if ( defined $opt_v ) { $VERBOSE = "Yep" ; }


# +--------+
# |  Main  |
# +--------+
# -- Preflight Checks
if ( ! -d $LIB_DIR )      { print "error:  Cannot find lib dir and no specific files listed.  Aborting.\n"   ; exit $E_GENERIC ; }
if ( $VERBOSE && $QUIET ) { print "error:  Cannot specify both 'quiet' (-q) and 'verbose (-v).  Aborting.\n" ; exit $E_GENERIC ; }

# -- Read Ze Files
&print_so("__verbose", "Hello\n") ;


# +----------------+
# |  Sub-Routines  |
# +----------------+
sub usage {
  print "finish this\n" ;
  exit ;
}

sub print_so {
  # This exists to print things to stdout, but respects the -q flag
  if ( $QUIET ) { return 0 ; }

  # If the message was intended to be for verbose output only, trigger here.
  if ( $_[0] eq "__verbose" ) {
    shift ;
    if ( $VERBOSE ) { print "@_" ; return 0 ; }
    else { return 0 ; }
  }

  # If we're here.  Then no QUIET or VERBOSE flags are set; just print the message.
  print "@_" ;
}
