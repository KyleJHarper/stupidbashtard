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
my $E_BAD_SYNTAX = 20 ;
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
  my $func = Function->new() ;
  my $fh ;
  open( $fh, '<', $_ ) or &fatal($E_IO_MISSING, "Unable to open file for reading:  $_ .") ;

  # Read file line by line and generate documentation.
  while ( <$fh> ) {
    chomp ;
    # If in a function, we shouldn't enter a new one.  If not in a function, enter one or skip this line.
    if (   $func->name() ) { &is_new_function($_) && &fatal($E_BAD_SYNTAX, "Found function declaration inside a function: " . $func->name()) ; }
    if ( ! $func->name() ) { &is_new_function($_) || next ; }

    # Update the brace count.  Leave if we haven't found one yet (new function with starting brace on next line).
    &count_braces( $_ );
    if ( ! $func->openedbraces() ) { next ; }
    if ( $func->braces_match() )   { $func->ready_to_leave("Yep") ; }

    # Read any tag that might exist.  Can't fail, and a line can only have 1 tag.
    &add_tag( $_ );

    # If we're ready to leave, save the function and re-instantiate it.
    if ( $func->ready_to_leave() ) { $func->save() ; $func = Function->new() ; }
  }
  close( $fh );
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
  if ( ! -r $LIB_DIR ) { &fatal($E_IO_MISSING, "Cannot find lib dir and no specific files listed.") ; }
  if ( ! -w $DOC_DIR ) { &fatal($E_IO_MISSING, "Cannot find doc dir specified: ${DOC_DIR}.") ; }

  # Check that we have files to work with.
  if ( $#FILES eq -1 ) { &fatal($E_IO_MISSING, "No files found for processing.") ; }
  foreach ( @FILES ) {
    if ( ! -f $_ )    { &fatal($E_IO_MISSING, "Cannot find specified file: $_ .") ; }
    if ( ! -r $_ )    { &fatal($E_IO_MISSING, "Cannot read specified file: $_ .") ; }
  }

  # Conflicting options
  if ( $VERBOSE && $QUIET ) { &fatal($E_GENERIC,    "Cannot specify both 'quiet' (-q) and 'verbose' (-v).") ; }
}


# --
# -- Crawler Functions
# --
sub count_braces {
  # Setup string and strip anything between quotes (braces inside quotes don't affect flow).
  my $line = @_ ;
  $line =~ s/["][^"]*["]// ;
  $line =~ s/['][^']*[']// ;

  # Count braces and update properties
  my $opened = $line =~ tr/\{// ;
  my $closed = $line =~ tr/\}// ;
  $func->openedbraces( $func->openedbraces() + $opened );
  $func->closedbraces( $func->closedbraces() + $closed );

  # Report an error if the closed braces outnumber opened ones.  This should never happen.
  if ( $func->openedbraces() < $func->closedbraces() ) { &fatal($E_BAD_SYNTAX, "Found extraneous closing braces in function: " . $func->name()) ; }
}

sub braces_match {
  # This primarily checks for braces to be greater than zero and matching, to signify we're out of a function.
  if ( $func->openedbraces() <  $func->closedbraces() ) { &fatal($E_BAD_SYNTAX, "Found extraneous closing braces in function: " . $func->name()) ; }
  if ( $func->openedbraces() >  $func->closedbraces() ) { return 0 ; }
  if ( $func->openedbraces() == 0 )                     { return 0 ; }
  if ( $func->openedbraces() == $func->closedbraces() ) { return 1 ; }
}

sub is_new_function {
  # Determine if this line is starting a new function
  if ( @_ =~ /^[\s]*function[\s]+([a-Z0-9_-]+)[\s]?/ ) { $func->name($1) ; }
  if ( @_ =~ /^[\s]*([a-Z0-9_-]+)[\s]*\([\s]*\) / )    { $func->name($1) ; }
  return 0;
}

sub leave_function {
  # This should be called when we have a loaded function object.
  $func->save();
  $func = Function->new();
}

# --
# -- Tag Functions
# --
sub add_tag {
  my $tag_name ;
  my $tag_text ;

  # Try to get a tag name and text.  Leave if we don't get a name.
  if ( @_ =~ /#@([\S]*)[\s]+(.*)/ ) { $tag_name = $1 ; $tag_text = $2 ; }
  if ( ! $tag_name ) { return 0 ; }

  # Test to see if name is 'opt_'.
  if ( $tag_name eq "opt_" ) {
    # IF CURRENT_OPT ISN'T SET; ERROR.
  }
}


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
  print STDERR "error:  $_[1]  (Aborting)\n" ;
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
