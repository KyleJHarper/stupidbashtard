#!/usr/bin/perl

# +------------------+
# |  Pre-Requisites  |
# +------------------+
# --Import required items
use strict ;
use warnings ;
use Getopt::Std ;
use Cwd 'abs_path' ;
use File::Basename ;


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
my $VERBOSE      = "" ;

# -- GetOpts Overrides
getopts('d:hqv') or &usage ;
our ($opt_d, $opt_h, $opt_q, $opt_v) ;
if ( defined $opt_d ) { $DOC_DIR = $opt_d ; }
if ( defined $opt_h ) { &usage            ; }
if ( defined $opt_q ) { $QUIET   = "Yep"  ; }
if ( defined $opt_v ) { $VERBOSE = "Yep"  ; }


# +--------+
# |  Main  |
# +--------+
&load_files ;
&preflight_checks ;
&print_so("${DOC_DIR}\n") ;


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

sub add_file { push ( @FILES, $_ ) ; }

sub preflight_checks {
  # Do the files and directories we need exist?
  if ( ! -d $LIB_DIR )      { &fatal($E_IO_MISSING, "Cannot find lib dir and no specific files listed.")    ; }
  if ( ! -d $DOC_DIR )      { &fatal($E_IO_MISSING, "Cannot find doc dir specified: ${DOC_DIR}")            ; }

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
