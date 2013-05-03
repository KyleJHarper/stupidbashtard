#!/usr/bin/perl

# +------------------+
# |  Pre-Requisites  |
# +------------------+
# -- Import required items
use strict ;
use warnings ;
use Getopt::Std ;
use Cwd 'abs_path' ;
use File::Basename ;
use lib '.' ;
use Function ;


# +-----------------------+
# |  Variables & Getopts  |
# +-----------------------+
# -- Order 1
my $SELF_DIR  = dirname ( abs_path( __FILE__ ) ) ;
# -- Order 2
my $LIB_DIR   = "${SELF_DIR}/../lib" ;
my $DOC_DIR   = "${SELF_DIR}/../doc" ;
# -- Order 9
my $E_GENERIC    =  1 ;
my $E_IO_MISSING = 10 ;
my @FILES ;
my $QUIET        = "" ;
my $TESTING      = "" ;
my $VERBOSE      = "" ;

# -- GetOpts Overrides
getopts('d:hqtv') or &usage ;
our ($opt_d, $opt_h, $opt_q, $opt_t, $opt_v) ;
if ( defined $opt_d ) { $DOC_DIR = $opt_d ; }
if ( defined $opt_h ) { &usage            ; }
if ( defined $opt_q ) { $QUIET   = "Yep"  ; }
if ( defined $opt_t ) { $TESTING = "Yep"  ; }
if ( defined $opt_v ) { $VERBOSE = "Yep"  ; }


# +--------+
# |  Main  |
# +--------+
# -- Load @FILES and run pre-flight checks.
&load_files ;
&preflight_checks ;

# -- If we're testing, run test output function and leave.
if ( $TESTING ) { &run_tests ; exit ; }

# -- Process @FILES now
foreach ( @FILES ) {
  # Reset variables and open the file.
  my $in_function = "" ;
  my $func = Function->new() ;
  my $fh ;
  open( $fh, '<', $_ ) or &fatal($E_IO_MISSING, "Unable to open file for reading:  $_ .") ;

  # Read file line by line and generate documentation.
  while ( <$fh> ) {
    chomp ;
    if ( ! $in_function ) { &enter_function $_ || next ; }
  } 
}

# +----------------+
# |  Sub-Routines  |
# +----------------+
sub load_files {
  # Pull files from ARGV list (already shifted), if any.
  foreach ( @ARGV ) { push ( @FILES, $_ ) ; }
  if ( $#FILES ne -1 ) { return 0 ; }

  # If nothing was in ARGV above, try to load files from LIB_DIR.
  @FILES = split("\n", `find $LIB_DIR -type f -iname '*.sh'` ) ;
}

sub preflight_checks {
  # Do the files and directories we need exist?
  if ( ! -r $LIB_DIR )      { &fatal($E_IO_MISSING, "Cannot find lib dir and no specific files listed.")    ; }
  if ( ! -w $DOC_DIR )      { &fatal($E_IO_MISSING, "Cannot find doc dir specified: ${DOC_DIR}.")           ; }

  # Check that we have files to work with.
  if ( $#FILES eq -1 )      { &fatal($E_IO_MISSING, "No files found for processing.")                       ; }
  foreach ( @FILES ) {
    if ( ! -f $_ )          { &fatal($E_IO_MISSING, "Cannot find specified file: $_ .")                     ; }
    if ( ! -r $_ )          { &fatal($E_IO_MISSING, "Cannot read specified file: $_ .")                     ; }
  }

  # Conflicting options
  if ( $VERBOSE && $QUIET ) { &fatal($E_GENERIC,    "Cannot specify both 'quiet' (-q) and 'verbose' (-v).") ; }
}


# --
# -- Crawler Functions
# --
sub enter_function {
# FINISH THIS REGEX
  if ( @_ =~ /^[\s]*function[\s]+([a-Z0-9_-]+)[\s]?/ ) { $func->name = $1 ; return 1 ; }
  if ( @_ =~ /^[\s]*(\S+)[\s]*\([\s]*\)
}

# --
# -- Tag Functions
# --

# --
# -- Testing Functions
# --
sub run_tests {
  # Print a normal message
  &print_so( "Test: normal message from print_so\n" ) ;

  # Print a verbose message
  &print_so_verbose( "Test: verbose message from print_so_verbose\n" ) ;
}


# --
# -- Printing Functions
# --
sub fatal {
  print STDERR "error:  $_[1]  Aborting\n" ;
  exit $_[0] ;
}

sub print_so {
  if ( $QUIET ) { return 0 ; } ;
  print @_ ;
}

sub print_so_verbose {
  if ( $VERBOSE ) { print @_ ; return 0 ; }
}

sub usage {
  print "USAGE:   finish this\n" ;
  exit $E_GENERIC ;
}
