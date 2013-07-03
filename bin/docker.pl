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


# +-----------------------+
# |  Variables & Getopts  |
# +-----------------------+
# -- Order 1
my $SELF_DIR  = dirname ( abs_path( __FILE__ ) ) ;
# -- Order 2
my $LIB_DIR   = "${SELF_DIR}/../lib" ;
my $DOC_DIR   = "${SELF_DIR}/../doc" ;
# -- Order 8
my $E_GOOD       =   0 ;  # Successful exit.
my $E_GENERIC    =   1 ;  # Generic failure, should likely never use this.
my $E_IO_FAILURE =  10 ;  # Any problems related to reading or writing to files.
my $E_BAD_SYNTAX =  20 ;  # Syntax problems invoking docker.
my $E_BAD_INPUT  =  30 ;  # Errors with the input given to docker for processing.
my $E_OH_SNAP    = 255 ;  # Fun
my @FILES              ;
my $QUIET        =  "" ;
my $TESTING      =  "" ;
my $VERBOSE      =  "" ;
# -- Order 9
my %defaults            ;
my $func                ;
my $inside_getopts = "" ;
my $getopts_offset = 0  ;
my $last_opt_name  = "" ;

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
if ( $TESTING ) { &run_tests ; exit $E_GOOD ; }

# -- Process @FILES now
foreach ( @FILES ) {
  # Reset variables and open the file.
  my $fh ;
  &reset_variables ;
  &reset_defaults  ;
  open( $fh, '<', $_ ) or &fatal($E_IO_FAILURE, "Unable to open file for reading:  " . $_ ) ;

  # Read file line by line and generate documentation.
  while ( <$fh> ) {
    chomp ;

    # If the whole line is blank or a comment, leave.
    if ( /^[\s]*$/ )      { next ; }
    if ( /^[\s]*#(?!@)/ ) { next ; }

    # If in a function, we shouldn't enter a new one.  If not in a function, enter one or skip this line.
    if (   $func->name() ) { &is_new_function($_) && &fatal($E_BAD_INPUT, "Found this function declaration inside a function: " . $func->name()) ; }
    if ( ! $func->name() ) {
      if ( /^[\s]*#@(Author|Date|Version|Namespace|Description)([\s]+(.*))?$/ ) { if ($3) { $defaults{$1} .= $3 ;} }
      &is_new_function($_) || next ;
    }

    # Update the brace count and see if they match.  If no braces are opened, continue.  If they match, flush and continue.
    $func->count_braces( $_ );
    if ( $func->opened_braces() < $func->closed_braces() ) { &fatal($E_BAD_INPUT, "Closed braces out-paced opening ones in function: " . $func->name()) ; }
    if ( ! $func->opened_braces() ) { next ; }
    if ( $func->braces_match() )    { &save_function() ; &reset_variables ; next ; }

    # Check for the invocation of getopts and setup the offset.  Offset will be +1 since braces are already counted.
    if ( /^[\s]*while[\s]+(getopts|core_getopts_Long)[\s]+['"]([a-zA-Z0-9 ]+)['"]/ ) {
      $inside_getopts = "Yep" ;
      $getopts_offset = $func->opened_braces() - $func->closed_braces();
    }
    # If we're in getopts we need to set the last_opt_name, if it changed.
    if ( $inside_getopts && /^[\s]*case[\s]+['"]?([a-zA-Z0-9]+)['"]?/ )       { $last_opt_name = $1  ; }
    if ( $getopts_offset gt $func->opened_braces() - $func->closed_braces() ) { $inside_getopts = "" ; }

    # Read any tag that might exist.  Can't fail, and a line can only have 1 tag.
    &add_tag( $_ );
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
  if ( ! -d $LIB_DIR ) { &fatal($E_IO_FAILURE, "Cannot find lib dir and no specific files listed.")  ; }
  if ( ! -r $LIB_DIR ) { &fatal($E_IO_FAILURE, "Cannot read lib dir.")                               ; }
  if ( ! -d $DOC_DIR ) { &fatal($E_IO_FAILURE, "Cannot find doc dir specified: ${DOC_DIR}.")         ; }
  if ( ! -w $DOC_DIR ) { &fatal($E_IO_FAILURE, "Cannot write to the doc dir specified: ${DOC_DIR}.") ; }

  # Check that we have files to work with.
  if ( $#FILES eq -1 ) { &fatal($E_IO_FAILURE, "No files found for processing.") ; }
  foreach ( @FILES ) {
    if ( ! -f $_ ) { &fatal($E_IO_FAILURE, "Cannot find specified file: $_ .") ; }
    if ( ! -r $_ ) { &fatal($E_IO_FAILURE, "Cannot read specified file: $_ .") ; }
  }

  # Conflicting options
  if ( $VERBOSE && $QUIET ) { &fatal($E_BAD_SYNTAX, "Cannot specify both 'quiet' (-q) and 'verbose' (-v).") ; }
}

sub save_function {
  # Confirm we have the requirements to save a function.
  if ( ! $func->name()             ) { &fatal($E_BAD_INPUT, "Cannot save function.  Name is blank.")        ; }
  if ( $func->opened_braces() == 0 ) { &fatal($E_BAD_INPUT, "Cannot save function.  No open braces found.") ; }

  # Load defaults if nothing was specified for soft-required tags.
  if ( $func->basic_tags("Author") eq "" )      { $func->basic_tags("Author",      $defaults{"Author"})      ; }
  if ( $func->basic_tags("Date") eq "" )        { $func->basic_tags("Date",        $defaults{"Date"})        ; }
  if ( $func->basic_tags("Version") eq "" )     { $func->basic_tags("Version",     $defaults{"Version"})     ; }
  if ( $func->basic_tags("Namespace") eq "" )   { $func->basic_tags("Namespace",   $defaults{"Namespace"})   ; }
  if ( $func->basic_tags("Description") eq "" ) { $func->basic_tags("Description", $defaults{"Description"}) ; }

  # Send a verbose message if any of the tags are missing.  Particularly the basic ones.
  if ( $func->basic_tags()    eq "" ) { &print_so("No basic tags found for function " . $func->name() . ".  Continuing.")            ; }
  if ( $func->variable_tags() eq "" ) { &print_so_verbose("No variable tags found for function " . $func->name() . ".  Continuing.") ; }
  if ( $func->exit_tags()     eq "" ) { &print_so_verbose("No exit tags found for function " . $func->name() . ".  Continuing.")     ; }
  if ( $func->option_tags()   eq "" ) { &print_so_verbose("No option tags found for function " . $func->name() . ".  Continuing.")   ; }

  # Setup file path and try to open the handle.
  my $file = $DOC_DIR . '/' . $func->name() ;
  my $file_handle ;
  if ( -f $file ) {
    &print_so_verbose("File exists, overwriting: " . $file) ;
    if ( ! -w $file ) { &fatal($E_IO_FAILURE, "Cannot overwrite file (permission denied).") ; }
  }
  open( $file_handle, '>', $file ) or &fatal($E_IO_FAILURE, "Unable to open file for writing while saving:  " . $file ) ;

  # Save the file to disk
  # -- Header
  print $file_handle "---\n"                                        or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "# File Generated by Docker\n"                 or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "# Date: " . `date +'%F %R'` . "\n"            or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "# UUID: " . `uuidgen` . "\n"                  or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "\n"                                           or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "name: " . $func->name() . "\n"                or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "tags:\n"                                      or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "  - argument:\n"                               or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  # -- Argument Tags
  foreach ( $func->argument_tags() ) {
    print $file_handle '    - ' . $_ . ": |\n"                           or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    print $file_handle '      ' . $func->argument_tags($_) . "\n"      or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }
  # -- Basic Tags
  print $file_handle "  - basic:\n"                               or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach ( $func->basic_tags() ) {
    print $file_handle '    - ' . $_ . ": |\n"                           or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    print $file_handle '      ' . $func->basic_tags($_) . "\n"      or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }
  # -- Exit Tags
  print $file_handle "  - exit:\n"                                or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach ( $func->exit_tags() ) {
    print $file_handle '    - ' . $_ . ": |\n"                           or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    print $file_handle '      ' . $func->exit_tags($_) . "\n"       or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }
  # -- Option Tags
  print $file_handle "  - option:\n"                              or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach ( $func->option_tags() ) {
    print $file_handle '    - ' . $_ . ": |\n"                           or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    print $file_handle '      ' . $func->option_tags($_) . "\n"     or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }
  # -- Variable Tags
  print $file_handle "  - variable:\n"                            or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach ( $func->variable_tags() ) {
    print $file_handle '    - ' . $_ . ": |\n"                           or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    foreach my $line (split /\n/, $func->variable_tags($_)) { print "      ${line}\n"; }
    print $file_handle '      ' . $func->variable_tags($_) . "\n"   or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }

  # Close the file and leave.
  close( $file_handle );
  return 1;
}


# --
# -- Crawler Functions
# --
sub is_new_function {
  # Determine if this line is starting a new function
  if ( /^[\s]*function[\s]+([a-zA-Z0-9_-]+)[\s]?/ ) { $func->name($1) ; return 1 ; }
  if ( /^[\s]*([a-zA-Z0-9_-]+)[\s]*\([\s]*\) / )    { $func->name($1) ; return 1 ; }
  return 0;
}

sub reset_variables {
  # This should be called when we have a loaded function object.
  $inside_getopts = "" ;
  $getopts_offset = 0  ;
  $last_opt_name  = "" ;

  # Initialize at least a new set of soft-required tags for function.
  undef $func ;
  $func = Function->new();
}

sub reset_defaults {
  %defaults = () ;
  $defaults{"Author"} = ""      ;
  $defaults{"Date"} = ""        ;
  $defaults{"Version"} = ""     ;
  $defaults{"Namespace"} = ""   ;
  $defaults{"Description"} = "" ;
}


# --
# -- Tag Functions
# --
sub add_tag {
  my $tag_name ;
  my $tag_text = "" ;

  # Try to get a tag name and text.  Leave if we don't get a name.
  if ( ! /#@[\S]+/ ) { return 0 ; }
  if ( /#@([\S]+)([\s]+(.*))?/ ) { $tag_name = $1 ; $tag_text = $3 ; }
  if ( ! $tag_name ) { &print_so_verbose("Passed the regex check to ensure this line has a tag, but somehow I can't find a name... odd.") ; return 0 ; }

  # If name is 'opt_', this is an inferred getopts tag.  We need to read current opt, otherwise we're screwed.
  if ( $tag_name eq "opt_" ) {
    if ( ! $last_opt_name ) { &print_se($func->name() . " - Implied opt tag'" . '#@opt_' . "' found, but cannot infer the option name.\n") ; return 0 ; }
    $tag_name .= $last_opt_name ;
  }
  if ( $tag_name =~ /^opt_[a-zA-Z0-9_]+/ ) {
    $func->option_tags($tag_name, $tag_text . "\n");
    return 1;
  }

  # If name is '$@', '$<number>', or '$*' these are argument tags.
  if ( $tag_name eq '$@' || $tag_name eq '$*' ) { $func->argument_tags(substr($tag_name, 1), $tag_text . "\n"); return 1; }
  if ( $tag_name =~ /\$[0-9]+/ )                { $func->argument_tags(substr($tag_name, 1), $tag_text . "\n"); return 1; }

  # If name is '$E_' this is an exit/error tag.
  if ( $tag_name eq '$E_' ) {
    if ( /^(.*[\s]+)?(E_[a-zA-Z0-9_]+)[=]/ ) { $tag_name .= $2 ; }
    if ( $tag_name eq '$E_' ) { &print_se($func->name() . " - Implied exit tag '" . '#@$E_' . "' found, but no exit constant found at the front of the line.\n") ; return 0 ; }
  }
  if ( $tag_name =~ /\$E_[a-zA-Z0-9_]+/ ) {
    $func->exit_tags(substr($tag_name, 1), $tag_text . "\n");
    return 1;
  }

  # If name is '$', this is an inferred variable tag.  We need to find '[whitespace]someVar=' to name the tag 'someVar'.
  if ( $tag_name eq '$' ) { if ( /^[\s]*([a-zA-Z_][a-zA-Z0-9_]*)[=]/ ) { $tag_name .= $1 ; } }
  if ( $tag_name eq '$' ) { if ( /^[\s]*(declare[\s]+-[a-zA-Z][\s])?local[\s]+([a-zA-Z_][a-zA-Z0-9_]*)/ ) { $tag_name .= $2 ; } }
  if ( $tag_name eq '$' ) { &print_se($func->name() . " - Implied variable tag '" . '#@$' . "' found, but no variable found at the front of the line.\n") ; return 0 ; }
  if ( $tag_name =~ /\$E_[a-zA-Z0-9_]+/ )        { $func->exit_tags(substr($tag_name, 1), $tag_text . "\n");     return 1; }
  if ( $tag_name =~ /\$[a-zA-Z_][a-zA-Z0-9_]*/ ) { $func->variable_tags(substr($tag_name, 1), $tag_text . "\n"); return 1; }

  # If name doesn't require inferrence, it's absolute.  Federated or line-end is irrelevant.
  $func->basic_tags($tag_name, $tag_text . "\n");
  return 1;
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
# -- Fatal, Usage, and Printing Functions
# --
sub fatal { &print_se($_[1] . "  (aborting)\n") ; exit $_[0] ; }

sub print_se {
  print STDERR "error:  @_" ;
}
sub print_so {
  if ( $QUIET ) { return 0 ; }
  print @_ ;
}
sub print_so_verbose {
  if ( $VERBOSE ) { print @_ ; return 0 ; }
}

sub usage {
  print "USAGE:   finish this\n" ;
  exit $E_GOOD ;
}
