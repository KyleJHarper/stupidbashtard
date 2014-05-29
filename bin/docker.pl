#!/usr/bin/perl

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.


# +------------------+
# |  Pre-Requisites  |
# +------------------+
# -- Import required items.  This is done at compile time!
use strict ;
use warnings ;
use Getopt::Std ;
use Cwd 'abs_path' ;
use File::Basename ;
use Switch ;
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
my $SBT_DIR   = "${SELF_DIR}/../sbt"  ;
# -- Order 3
my $E_GOOD       =   0 ;  # Successful exit.
my $E_GENERIC    =   1 ;  # Generic failure, should likely never use this.
my $E_IO_FAILURE =  10 ;  # Any problems related to reading or writing to files.
my $E_BAD_SYNTAX =  20 ;  # Syntax problems invoking docker.
my $E_BAD_INPUT  =  30 ;  # Errors with the input given to docker for processing.
my $E_OH_SNAP    = 255 ;  # Fun
my @FILES              ;
my $QUIET        =  '' ;
my $TESTING      =  '' ;
my $USE_DEFAULTS = 'y' ;
my $VERBOSE      =  '' ;
my $OPT_CC       = '[:a-zA-Z0-9,]' ;  # Character class for getopts options
my $FIRST_VAR_CC = '[a-zA-Z_]'     ;  # Character class for first character of a variable
my $VAR_CC       = '[a-zA-Z0-9_]'  ;  # Character class for second and beyond characters of a variable
my $FUNC_CC      = '[a-zA-Z0-9_-]' ;  # Character class for function names
# -- Order 9
my %defaults            ;
my $func                ;
my $inside_getopts = '' ;
my $getopts_offset = 0  ;
my $last_opt_name  = '' ;
my $line_num       = 0  ;
my $saw_return     = '' ;

# -- GetOpts Overrides
getopts('d:hnqtuv') or &usage ;
our ($opt_d, $opt_h, $opt_n, $opt_q, $opt_t, $opt_v) ;
if ( defined $opt_d ) { $DOC_DIR      = $opt_d ; }
if ( defined $opt_h ) { &usage                 ; }
if ( defined $opt_n ) { $USE_DEFAULTS = ''     ; }
if ( defined $opt_q ) { $QUIET        = "Yep"  ; }
if ( defined $opt_t ) { $TESTING      = "Yep"  ; }
if ( defined $opt_v ) { $VERBOSE      = "Yep"  ; }


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
  $line_num = 0 ;
  &reset_variables ;
  %defaults = () ;
  open( $fh, '<', $_ ) or &fatal($E_IO_FAILURE, "Unable to open file for reading:  " . $_ ) ;

  # Read file line by line and generate documentation.
  while ( <$fh> ) {
    # If the whole line is blank or a comment, leave.
    chomp ;
    $line_num++;
    if ( /^[\s]*$/ )      { next ; }
    if ( /^[\s]*#(?!@)/ ) { next ; }

    # If in a function, we shouldn't enter a new one.  If not in a function, enter one or skip this line.
    if (   $func->name() ) { &is_new_function($_) && &fatal($E_BAD_INPUT, "Found this function declaration inside a function on line $line_num: " . $func->name()) ; }
    if ( ! $func->name() ) {
      if ( /^[\s]*#@([\S]+)[\s]+(.*)?$/ ) {
        if ( $USE_DEFAULTS ) { $defaults{$1} .= $2 =~ s/^-//r . "\n" ; }
      }
      &is_new_function($_) || next ;
    }

    # Update the brace count and see if they match.  If no braces are opened, continue.
    $func->count_braces( $_ );
    if ( $func->opened_braces() < $func->closed_braces() ) { &fatal($E_BAD_INPUT, "Closed braces out-paced opening ones on line $line_num in function: " . $func->name()) ; }
    if ( ! $func->opened_braces() ) { next ; }

    # Scan the line for multiple things to help build YAML data with later.
    &add_options( $_ )  ;
    &add_tag( $_ )      ;
    &add_variable( $_ ) ;
    &add_tools( $_ )    ;

    # If the braces match, save and leave.
    if ( $func->braces_match() ) { &save_function() ; &reset_variables ; next ; }
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

  # If nothing was in ARGV above, try to load files from SBT_DIR.
  @FILES = split("\n", `find $SBT_DIR -type f -iname '*.sh'` ) ;
}

sub preflight_checks {
  # Do the files and directories we need exist?
  if ( ! -d $SBT_DIR ) { &fatal($E_IO_FAILURE, "Cannot find sbt dir and no specific files listed.")  ; }
  if ( ! -r $SBT_DIR ) { &fatal($E_IO_FAILURE, "Cannot read sbt dir.")                               ; }
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
  my @TAG_TYPES = ( 'argument', 'basic', 'exit', 'option', 'variable' );

  # Confirm we have the requirements to save a function.
  if ( ! $func->name()             ) { &fatal($E_BAD_INPUT, 'Cannot save function.  Name is blank.')        ; }
  if ( $func->opened_braces() == 0 ) { &fatal($E_BAD_INPUT, 'Cannot save function.  No open braces found.') ; }

  # Load defaults if nothing was specified for soft-required tags.
  foreach my $key ( keys %defaults ) {
    if ( $key eq 'Description' ) { next ; }
    if ( ! $func->tags('basic', $key) ) { $func->tags('basic', $key, $defaults{$key}) ; }
  }

  # Send a verbose message if any of the expected basic tags are missing.
  foreach my $tag_type ( @TAG_TYPES ) {
    if ( ! $func->tags($tag_type) ) { &print_so_verbose("No $tag_type tags found for function " . $func->name() . '.  Continuing.') ; }
  }

  # Setup file path and try to open the handle.
  my $file = $DOC_DIR . '/' . $func->name() . '.yaml' ;
  my $file_handle ;
  if ( -f $file ) {
    &print_so_verbose('File exists, overwriting: ' . $file) ;
    if ( ! -w $file ) { &fatal($E_IO_FAILURE, 'Cannot overwrite file (permission denied).') ; }
  }
  open( $file_handle, '>', $file ) or &fatal($E_IO_FAILURE, 'Unable to open file for writing while saving:  ' . $file ) ;

  # Save the file to disk
  # -- Header
  print $file_handle "# File Generated by Docker\n"                     or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "# Date: " . `date +'%F %R'`                       or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "# UUID: " . `uuidgen` . "\n"                      or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "---\n"                                            or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "\nname: " . $func->name() . "\n"                  or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle "\ntags:\n"                                        or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  # -- Tags
  foreach my $tag_type ( @TAG_TYPES ) {
    print $file_handle "  ${tag_type}:\n"                               or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    foreach ( $func->tags($tag_type) ) {
      print $file_handle '    - name: ' . $_ . "\n"                     or &fatal($E_IO_FAILURE, "Failure writing line to file.");
      print $file_handle "      text: |\n"                              or &fatal($E_IO_FAILURE, "Failure writing line to file.");
      foreach my $line (split /\n/, $func->tags($tag_type, $_)) {
        print $file_handle "        ${line}\n"                          or &fatal($E_IO_FAILURE, "Failure writing line to file.");
      }
    }
  }
  # -- Options
  print $file_handle "\noptions:\n"                                     or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach ( $func->options() ) {
    print $file_handle '  ' . $_ . ': ' . $func->options($_) . "\n"     or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }
  # -- Required Tools
  print $file_handle "\nrequired_tools:\n"                              or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach ( split /,/, $func->tools() ) {
    print $file_handle '  - ' . $_ . "\n"                               or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  }
  # -- Thread Safe
  print $file_handle "\nthread_safe: " . $func->thread_safe() . "\n"    or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  # -- Allow Indirect Output
  print $file_handle "\nallow_indirect_output: "                        or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  print $file_handle $func->indirect_output() . "\n"                    or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  # -- Variables
  print $file_handle "\nvariables:\n"                                   or &fatal($E_IO_FAILURE, "Failure writing line to file.");
  foreach my $variable ( $func->variables() ) {
    print $file_handle "  - name: ${variable}\n"                        or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    foreach my $property ( $func->variables($variable) ) {
      print $file_handle "    $property: "                              or &fatal($E_IO_FAILURE, "Failure writing line to file.");
      print $file_handle $func->variables($variable, $property) . "\n"  or &fatal($E_IO_FAILURE, "Failure writing line to file.");
    }
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
  if ( /^[\s]*function[\s]+(${FUNC_CC}+)[\s]?/ ) { $func->name($1) ; return 1 ; }
  if ( /^[\s]*(${FUNC_CC}+)[\s]*\([\s]*\) / )    { $func->name($1) ; return 1 ; }
  return 0;
}

sub reset_variables {
  # This should be called when we have a loaded function object.
  $inside_getopts = '' ;
  $getopts_offset = 0  ;
  $last_opt_name  = '' ;
  $saw_return     = '';

  # Initialize at least a new set of soft-required tags for function.
  undef $func ;
  $func = Function->new();
}

sub add_tools {
  # Search for core_ToolExists to build a list of required tools
  if ( /core_ToolExists(([\s]+['"]?[a-zA-Z0-9_\-.\/]+['"]?)+)/ ) {
    TOOL: foreach my $tool ( split / /, $1 ) {
      if ( ! $tool ) { next ; }
      foreach my $existing_tool ( split /,/, $func->tools() ) {
        if ( $existing_tool eq $tool ) { next TOOL ; }
      }
      $func->tools( $tool ) ;
    }
  }
}

sub add_variable {
  my $flags = '';
  my $flag_switches = '';
  my $name  = '';
  my $value = '';
  my $scope = 'top';

  # If declare is present, set the local scope and get the flags.  Allow 2x declare/local combo since bash does... ugh.
  # Using declare/local allows you to create a variable without specifying a value (otherwise, it'd be seen as a function/command call).
  if ( /^[\s]*(declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*)((declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*))?(${FIRST_VAR_CC}${VAR_CC}*)([=](.*))?/ ) {
    $name  = $8 ;
    $scope = 'local' ;
    if (  $2 ) { $flag_switches .=  $2 ; }
    if (  $6 ) { $flag_switches .=  $6 ; }
    if ( $10 ) { $value          = $10 ; }
    $flag_switches =~ s/[^a-zA-Z]// ;
    foreach my $flag ( split /-/, $flag_switches ) {
      switch ($flag) {
        case /a/  { $flags .= 'array '     ; }
        case /A/  { $flags .= 'hash '      ; }
        case /i/  { $flags .= 'integer '   ; }
        case /l/  { $flags .= 'lowercase ' ; }
        case /r/  { $flags .= 'readonly '  ; }
        case /u/  { $flags .= 'uppercase ' ; }
        else      { &print_so_verbose("Found a declare switch I don't have a mapping for: $flag") ; }
      }
    }
  }

  # If no name yet, scan for a non-local variable.  It must have a value assigned or it'll be interpreted as a command or function call.
  if ( ! $name ) {
    if ( /^[\s]*(${FIRST_VAR_CC}${VAR_CC}*)[=](.*)/ ) {
      $name  = $1 ;
      $value = $2 ;
    }
  }

  # If we still don't have a name, then we need to leave.
  if ( ! $name ) { return 0 ; }

  # Trim the line-end comments to derive the true default value sent, if any.
  my $in_quote = '';
  my $escape   = '';
  my $new_value = '';
  foreach my $char ( split //, $value ) {
    $new_value .= $char ;
    if (   $escape                         ) { $escape = ''      ; next ; }
    if ( ! $escape   && $char eq '\\'      ) { $escape = 'yep'   ; next ; }
    if (   $in_quote && $char eq $in_quote ) { $in_quote = ''    ; next ; }
    if ( ! $in_quote && $char =~ /["']/    ) { $in_quote = $char ; next ; }
    if ( ! $in_quote && $char eq '#'       ) { $new_value = substr($new_value, 0, -1) ; last ; }
    if ( ! $in_quote && $char eq ';'       ) { $new_value = substr($new_value, 0, -1) ; last ; }
  }
  $value = $new_value;
  $value =~ s/^[\s]*//g ;
  $value =~ s/[\s]*$//g ;

  # Variables can be found multiple times due to assignments.  Scan for existing name and abort if found.
  foreach my $existing_name ( $func->variables() ) {
    if ( $name eq $existing_name ) { return 1 ; }
  }

  # Thread safe killed if non local variable found.
  if ( $scope eq 'top' ) { $func->thread_safe('false') ; }

  # Load the info into our function object.
  $func->variables($name, 'scope', $scope);
  $func->variables($name, 'value', $value);
  $func->variables($name, 'flags', $flags);
  return 1 ;
}

sub add_options {
  # This will check for getopts invocation and process the available options.
  my $GETOPT_TYPE   ;
  my $SHORT_OPTS    ;
  my $LONG_OPTS     ;
  my $last_opt = '' ;

  if ( /^[\s]*while[\s]+((core_)?getopts)[\s]+['"](${OPT_CC}+)['"][\s]+${FIRST_VAR_CC}${VAR_CC}*([\s]+['"](${OPT_CC}+)['"])?/ ) {
    $GETOPT_TYPE = $1 ;
    $SHORT_OPTS  = $3 ;
    $LONG_OPTS   = $5 ;
    $inside_getopts = "Yep" ;
    $getopts_offset = $func->opened_braces() - $func->closed_braces();
  }

  # Strip leading colon (supposed to signal internal error handling).
  $SHORT_OPTS && $SHORT_OPTS =~ s/^:// ;
  $LONG_OPTS  && $LONG_OPTS  =~ s/^:// ;

  # Do some checking in case we find a problem
  if ( ! $SHORT_OPTS && ! $LONG_OPTS ) { &print_so_verbose('Found a getopts block, but  no long or short options were sent.  Just FYI.') ; return 0 ; }
  if ( $GETOPT_TYPE eq 'core_getopts' && ! $LONG_OPTS ) { &print_so_verbose('Found core_getopts but no long opts were sent.  Just FYI.') ; }

  # Process short opts
  if ( $SHORT_OPTS ) {
    foreach my $opt ( split //, $SHORT_OPTS ) {
      if ( $opt eq 'R' ) { $func->indirect_output('true')    ;        }
      if ( $opt eq ':' ) { $func->options($last_opt, 'true') ; next ; }
      $func->options($opt, 'false') ;
      $last_opt = $opt ;
    }
  }

  # Process long opts
  if ( $LONG_OPTS ) {
    foreach my $opt ( split /,/, $LONG_OPTS ) {
      if ( $opt =~ /:$/ ) { $func->options(substr($opt, 0, -1), 'true') ; next ; }
      $func->options($opt, 'false') ;
      $last_opt = $opt ;
    }
  }
  return 1;
}

sub add_tag {
  my $tag_name ;
  my $tag_text = "" ;

  # If we're in getopts we need to set the last_opt_name, if it changed.
  if ( $inside_getopts && /^[\s]*(([\s]*['"]?${OPT_CC}+['"]?[\s]*\|?)+)\)/ ) { $last_opt_name = $1  ; }
  if ( $getopts_offset gt $func->opened_braces() - $func->closed_braces() )  { $inside_getopts = "" ; }

  # Try to get a tag name and text.  Leave if we don't get a name.
  if ( ! /#@[\S]+/ ) { return 0 ; }
  if ( /#@([\S]+)([\s]+(.*))?/ ) { $tag_name = $1 ; $tag_text = $3 ; }
  if ( ! $tag_name ) { &print_so_verbose("Passed the regex check to ensure this line has a tag, but somehow I can't find a name... odd.") ; return 0 ; }

  # If name is 'opt_', this is an inferred getopts tag.  We need to read current opt, otherwise we're screwed.
  if ( $tag_name eq "opt_" ) {
    if ( ! $last_opt_name ) { &print_se($func->name() . " - Implied opt tag'" . '#@opt_' . "' found, but cannot infer the option name on line $line_num.\n") ; return 0 ; }
    foreach ( split /\|/, $last_opt_name ) {
      s/(['"]|[\s])//g;
      $func->tags('option', $_, $tag_text . "\n");
    }
    return 1;
  }
  if ( $tag_name =~ /^opt_${OPT_CC}+/ ) {
    $func->tags('option', substr($tag_name, 4), $tag_text . "\n");
    return 1;
  }

  # If name is '$@', '$<number>', or '$*' these are argument tags.
  if ( $tag_name eq '$@' || $tag_name eq '$*' ) { $func->tags('argument', substr($tag_name, 1), $tag_text . "\n"); return 1; }
  if ( $tag_name =~ /\$[0-9]+/ )                { $func->tags('argument', substr($tag_name, 1), $tag_text . "\n"); return 1; }

  # If name is '$E_' this is an exit/error tag.
  if ( $tag_name eq '$E_' ) {
    if ( /^(.*[\s]+)?(E_${VAR_CC}+)[=]/ ) { $tag_name .= $2 ; }
    if ( $tag_name eq '$E_' ) { &print_se($func->name() . " - Implied exit tag '" . '#@$E_' . "' found, but no exit constant found at the front of the line on line $line_num.\n") ; return 0 ; }
  }
  if ( $tag_name =~ /\$E_${VAR_CC}+/ ) {
    $func->tags('exit', substr($tag_name, 1), $tag_text . "\n");
    return 1;
  }

  # If name is '$', this is an inferred variable tag.  We need to find '[whitespace]someVar=' to name the tag 'someVar'.
  if ( $tag_name eq '$' ) {
    if ( /^[\s]*(${FIRST_VAR_CC}${VAR_CC}*)[=]/ ) { $tag_name .= $1 ; }
  }
  if ( $tag_name eq '$' ) {
    if ( /^[\s]*(declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*)((declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*))?(${FIRST_VAR_CC}${VAR_CC}*)([=](.*))?/ ) {
      $tag_name .= $8 ;
    }
  }
  if ( $tag_name eq '$' ) { &print_se($func->name() . " - Implied variable tag '" . '#@$' . "' found, but no variable found at the front of the line on line $line_num.\n") ; return 0 ; }
  if ( $tag_name =~ /\$E_${VAR_CC}+/ )              { $func->tags('exit',     substr($tag_name, 1), $tag_text . "\n"); return 1; }
  if ( $tag_name =~ /\$${FIRST_VAR_CC}${VAR_CC}*/ ) { $func->tags('variable', substr($tag_name, 1), $tag_text . "\n"); return 1; }

  # If name doesn't require inferrence, it's absolute.  Federated or line-end is irrelevant.
  $func->tags('basic', $tag_name, $tag_text . "\n");
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
  print "@_\n" ;
}
sub print_so_verbose {
  if ( $VERBOSE ) { print "@_\n" ; return 0 ; }
}

sub usage {
  print "USAGE:   finish this\n" ;
  exit $E_GOOD ;
}
