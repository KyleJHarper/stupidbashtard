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
use feature 'switch' ;
use lib dirname ( abs_path( __FILE__ ) ) ;
use Function ;


# +-----------------------+
# |  Variables & Getopts  |
# +-----------------------+
# -- Order 1
my $SELF_DIR  = dirname ( abs_path( __FILE__ ) ) ;
# -- Order 2
my $DOC_DIR   = "${SELF_DIR}/../doc" ;
my $SBT_DIR   = "${SELF_DIR}/../sbt"  ;
# -- Order 3
my $E_GOOD       =   0 ;  # Successful exit.
my $E_GENERIC    =   1 ;  # Generic failure, should likely never use this.
my $E_IO_FAILURE =  10 ;  # Any problems related to reading or writing to files.
my $E_BAD_SYNTAX =  20 ;  # Syntax problems invoking Shocker.
my $E_BAD_INPUT  =  30 ;  # Errors with the input given to Shocker for processing.
my $E_OH_SNAP    = 255 ;  # Fun
my @FILES              ;
my $QUIET        =  '' ;
my $TESTING      =  '' ;
my $VERBOSE      =  '' ;
my $OPT_CC       = '[:a-zA-Z0-9,_-]' ;  # Character class for getopts options
my $FIRST_VAR_CC = '[a-zA-Z_]'       ;  # Character class for first character of a variable
my $VAR_CC       = '[a-zA-Z0-9_]'    ;  # Character class for second and beyond characters of a variable
my $FUNC_CC      = '[a-zA-Z0-9_]'    ;  # Character class for function names (some others technically work, but aren't supported)
# -- Order 9
my %namespace_tags      ;
my $func                ;
my $inside_getopts = '' ;
my $getopts_offset = 0  ;
my $last_opt_name  = '' ;
my $line_num       = 0  ;
my $saw_return     = '' ;
my $current_file   = '' ;

# -- GetOpts Overrides
getopts('d:hqtuv') or &usage ;
our ($opt_d, $opt_h, $opt_n, $opt_q, $opt_t, $opt_v) ;
if ( defined $opt_d ) { $DOC_DIR      = $opt_d ; }
if ( defined $opt_h ) { &usage                 ; }
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
  %namespace_tags = () ;
  $current_file = $_ ;
  open( $fh, '<', $_ ) or &fatal($E_IO_FAILURE, "Unable to open file for reading:  " . $_ ) ;

  # Read file line by line and generate documentation.
  while ( <$fh> ) {
    # Decide if we should even process the line...
    chomp ;                           # We don't care about trailing spaces.
    $line_num++;                      # Increment line number.
    if ( /^[\s]*$/ )      { next ; }  # Blank lines mean nothing.
    if ( /^[\s]*#(?!@)/ ) { next ; }  # Comments mean nothing, unless it's the Shocker tag format:  #@

    # If we're in a function, we shouldn't enter a new one.  If not in a function, enter one or skip this line because we only audit functions.
    if (   $func->name() ) { &is_new_function($_) && &fatal($E_BAD_INPUT, "Found this function declaration inside a function on line $line_num: " . $func->name()) ; }
    if ( ! $func->name() ) {
      if ( /^[\s]*#@([\S]+)[\s]+(.*)?$/ ) {
        # We're not in a function, but we have a Shocker tag:  #@something.  Store it as a namespace tag.  Replace '-' with a newline, per standards.
        $namespace_tags{$1} .= $2 =~ s/^-//r . "\n" ;
      }
      &is_new_function($_) || next ;
    }

    # Update the brace count and see if they match.  If no braces are opened then we're not inside the function yet; continue.
    $func->count_braces( $_ );
    if ( $func->opened_braces() < $func->closed_braces() ) { &fatal($E_BAD_INPUT, "Closed braces out-paced opening ones on line $line_num in function: " . $func->name()) ; }
    if ( $func->opened_braces() == 0 ) { next ; }

    # Track the depth of loops we're in for getopts tracking.  This is fooled by (expr ; do cmd ; done) but getopts should never, ever be inside something like that.
    $func->count_loops( $_ );
    if ( $func->loop_level < 0 ) { &fatal($E_BAD_INPUT, "Loop level went negative on line $line_num in function: " . $func->name()) ; }

    # Scan the line for multiple things to help build YAML data with later.
    &add_options( $_ )  ;
    &add_tag( $_ )      ;
    &add_variable( $_ ) ;

    # If the braces match, save and leave.
    if ( $func->braces_match() ) { &save_function();  &reset_variables; next; }
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
  my @TAG_TYPES = ( 'variable' );
  my $line_count = 0;
  my $quote = '';
  my $flags = '';
  my $description = '';
  my $token = '';

  # Confirm we have the requirements to save a function.
  if ( ! $func->name()             ) { &fatal($E_BAD_INPUT, 'Cannot save function.  Name is blank.')        ; }
  if ( $func->opened_braces() == 0 ) { &fatal($E_BAD_INPUT, 'Cannot save function.  No open braces found.') ; }

  # Send a verbose message if any of the expected basic tags are missing.
  foreach my $tag_type ( @TAG_TYPES ) {
    if ( ! $func->tags($tag_type) ) { &print_so_verbose("No $tag_type tags found for function " . $func->name() . '.  Continuing.') ; }
  }

  # Compare the options and give a warning if an option exists that doesn't have a description (tag).
#TODO

  # Setup file path and try to open the handle.
  my $file = $DOC_DIR . '/' . $func->name() . '.yaml' ;
  my $file_handle ;
  if ( -f $file ) {
    &print_so_verbose('File exists, overwriting: ' . $file) ;
    if ( ! -w $file ) { &fatal($E_IO_FAILURE, 'Cannot overwrite file (permission denied).') ; }
  }
  open( $file_handle, '>', $file ) or &fatal($E_IO_FAILURE, 'Unable to open file for writing while saving:  ' . $file ) ;

  # Save the file to disk
  # -- Header & Basic Info
  print $file_handle "# File Generated by Shocker\n" ;
  print $file_handle "# Date: " . `date +'%F %R'` ;
  print $file_handle "---\n" ;
  print $file_handle "\n" ;
  print $file_handle "# Function details & basic info.\n" ;
  print $file_handle "Function: " . $func->name() . "\n" ;
  foreach my $key ( sort $func->tags('basic') ) {
    $line_count = $func->tags('basic', $key) =~ tr/\n// ;
    if ( $line_count > 1) {
      print $file_handle $key . ": |\n" ;
      foreach my $line (split /\n/, $func->tags('basic', $key)) {
        if ($line ne '') {
          print $file_handle "  " ;
        }
        print $file_handle $line . "\n" ;
      }
    } else {
      $description = $func->tags('basic', $key) ;
      chomp $description ;
      $description =~ s/'/''/g ;
      print $file_handle $key . ": '" . $description . "'\n" ;
    }
  }
  print $file_handle "allow_indirect_output: " ;
  print $file_handle $func->indirect_output() . "\n" ;
  print $file_handle "thread_safe: " . $func->thread_safe() . "\n" ;
  print $file_handle "\n" ;

  # -- Dependencies
  print $file_handle "# Dependencies\n" ;
  if ($func->tags('dependency', 'all')) {
    print $file_handle "dependencies:\n" ;
    foreach my $dep ( split /\n/, $func->tags('dependency', 'all') ) {
      $description = $dep;
      $description =~ s/'/''/g ;
      print $file_handle "  - '" . $description . "'\n" ;
    }
  } else {
    print $file_handle "dependencies: []\n" ;
  }
  print $file_handle "\n" ;

  # -- Parameters & Options
  print $file_handle "# Parameters & Options (switches and positionals)\n" ;
  print $file_handle "parameters:\n" ;
  foreach my $param ( sort $func->tags('argument')) {
    $quote = '';
    if ($param =~ /[\@\*]/ ) { $quote = "'" }
    print $file_handle "  " . $quote . $param . $quote . ":\n" ;
    $line_count = $func->tags('argument', $param) =~ tr/\n// ;
    if ( $line_count > 1 ) {
      print $file_handle "    description: |\n" ;
      foreach my $line (split /\n/, $func->tags('argument', $param)) {
        if ($line ne '') {
          print $file_handle "      " ;
        }
        print $file_handle $line . "\n" ;
      }
    } else {
      $description = $func->tags('argument', $param);
      chomp $description ;
      $description =~ s/'/''/g ;
      print $file_handle "    description: '" . $description . "'\n" ;
    }
  }
  foreach my $opt ( sort $func->options() ) {
    print $file_handle "  " . $opt . ":\n" ;
    print $file_handle "    requires_optarg: " . $func->options($opt) . "\n" ;
    $line_count = $func->tags('option', $opt) =~ tr/\n// ;
    if ( $line_count > 1) {
      print $file_handle "    description: |\n" ;
      foreach my $line (split /\n/, $func->tags('option', $opt)) {
        if ($line ne '') {
          print $file_handle "      " ;
        }
        print $file_handle $line . "\n" ;
      }
    } else {
      $description = $func->tags('option', $opt) ;
      chomp $description ;
      $description =~ s/'/''/g ;
      print $file_handle "    description: '" . $description . "'\n" ;
    }
  }
  print $file_handle "\n" ;

  # -- Variables & Exit Codes
  print $file_handle "# Variables & Exit Codes\n" ;
  print $file_handle "variables:\n" ;
  foreach my $var ( sort $func->variables() ) {
    print $file_handle "  " . $var . ":\n";
    # Description
    if ( $func->tags('variable', $var) ) {
      $line_count = $func->tags('variable', $var) =~ tr/\n// ;
      if ($line_count > 1) {
        print $file_handle "    description: |\n" ;
        foreach my $line (split /\n/, $func->tags('variable', $var)) {
          if ($line ne '') {
            print $file_handle "      " ;
          }
          print $file_handle $line . "\n" ;
        }
      } else {
        $description = $func->tags('variable', $var) ;
        chomp $description ;
        $description =~ s/'/''/g ;
        print $file_handle "    description: '" . $description . "'\n";
      }
    } else {
      print $file_handle "    description:\n" ;
    }
    # Is Exit Variable?
    if ($var =~ /E_/ ) { print $file_handle "    exit_var: true\n"  ; }
    else               { print $file_handle "    exit_var: false\n" ; }
    # Scope, Flags, and Default Value
    foreach my $property ($func->variables($var)) {
      # -- Flags:  store them in an array.
      if ($property eq 'flags' ) {
        $flags = $func->variables($var, $property);
        $flags =~ s/([\S]+)/'$1'/g ;
        $flags =~ s/[\s]+$// ;
        $flags =~ s/[\s]+/,/g ;
        print $file_handle "    ${property}: [" . $flags . "]\n" ;
        next ;
      }
      # -- Values (Array):  split them up.
      if ($property eq 'value' && $flags =~ /array/) {
        my $in_quote  = '';
        my $escape    = '';
        my $new_value = '';
        my @values    = ();
        $token = $func->variables($var, $property) ;
        $token =~ s/(^\([\s]*|[\s]*\)$)//g ;
        foreach my $char ( split //, $token ) {
          $new_value .= $char ;
          if (   $new_value =~ /^\s+$/           ) { next ; }
          if (   $escape                         ) { $escape = ''      ; next ; }
          if ( ! $escape   && $char eq '\\'      ) { $escape = 'yep'   ; next ; }
          if (   $in_quote && $char eq $in_quote ) { $in_quote = ''    ; next ; }
          if ( ! $in_quote && $char =~ /["']/    ) { $in_quote = $char ; next ; }
          if ( ! $in_quote && $char =~ /\s/      ) {
            $new_value =~ s/(^\s*|\s*$)//g ;
            $new_value =~ s/'/''/g ;
            $new_value =~ s/^''// ;
            $new_value =~ s/''$// ;
            push @values, $new_value ;
            $new_value = '' ;
            next ;
          }
        }
        $new_value =~ s/(^\s*|\s*$)//g ;
        $new_value =~ s/'/''/g ;
        push @values, $new_value ;
        print $file_handle "    value:\n" ;
        foreach ( @values ) {
          $quote = "'";
          if ($new_value =~ /^[0-9]+$/ ) { $quote = '' ; }
          print $file_handle "      - ${quote}$_${quote}\n" ;
        }
        next ;
      }
      # -- Values (Hash):  store as key-value pairs.
      if ($property eq 'value' && $flags =~ /hash/) {
        my $in_quote  = '';
        my $escape    = '';
        my $new_value = '';
        my $new_key   = '';
        my $keys      = {};
        $token = $func->variables($var, $property) ;
        $token =~ s/(^\([\s]*|[\s]*\)$)//g ;
        foreach my $char ( split //, $token ) {
          $new_value .= $char ;
          if (   $new_value =~ /^\s+$/           ) { next ; }
          if ( ! $new_key  && $char eq '['       ) { next ; }
          if (   $escape                         ) { $escape = ''      ; next ; }
          if ( ! $escape   && $char eq '\\'      ) { $escape = 'yep'   ; next ; }
          if (   $in_quote && $char eq $in_quote ) { $in_quote = ''    ; next ; }
          if ( ! $in_quote && $char =~ /["']/    ) { $in_quote = $char ; next ; }
          if ( ! $new_key  && $char =~ /\s/      ) { next ; }
          if ( ! $new_key  && $char eq ']'       ) { $new_key = $new_value ; $new_value = '' ; next ; }
          if ( ! $in_quote && $char =~ /\s/      ) {
            $new_value =~ s/(^\s*=|\s*$)//g ;
            $new_value =~ s/'/''/g ;
            $new_value =~ s/^''// ;
            $new_value =~ s/''$// ;
            $new_key =~ s/(^\s*|\s*$)//g ;
            $new_key =~ s/[\[\]]//g ;
            if ($new_key =~ /^['"]\S+['"]$/ ) { $new_key =~ s/(^['"]|['"]$)//g ; }
            if ($new_key =~ /\s/) { $new_key = "'${new_key}'" } ;
            $keys->{$new_key} = $new_value ;
            $new_value = '' ;
            $new_key = '' ;
            next ;
          }
        }
        $new_value =~ s/(^\s*=|\s*$)//g ;
        $new_value =~ s/'/''/g ;
        $new_key =~ s/(^\s*|\s*$)//g ;
        $new_key =~ s/[\[\]]//g ;
        if ($new_key =~ /^['"]\S+['"]$/ ) { $new_key =~ s/(^['"]|['"]$)//g ; }
        if ($new_key =~ /\s/) { $new_key = "'${new_key}'" } ;
        $keys->{$new_key} = $new_value ;
        print $file_handle "    value:\n" ;
        foreach ( sort keys $keys ) {
          if ($_ eq '') { next ; }
          $quote = "'";
          if ($keys->{$_} =~ /^[1-9]+$/ ) { $quote = '' ; }
          print $file_handle "      $_: ${quote}$keys->{$_}${quote}\n" ;
        }
        next ;
      }
      # Values (String/Numeric):  Save as-is, spanning lines if necessary.
      if ($property eq 'value') {
        $token = $func->variables($var, $property) ;
        my $line_count = $token =~ tr/\n// ;
        if ($line_count > 1 ) {
          $token =~ s/^['"]// ;
          $token =~ s/['"]$// ;
          print $file_handle "    value: |\n" ;
          foreach (split /\n/, $token) {
            print $file_handle "      " . $_ . "\n";
          }
          next ;
        }
        $quote = "'";
        $token =~ s/'/''/g ;
        $token =~ s/^''// ;
        $token =~ s/''$// ;
        if ($token =~ /^[0-9]+$/ ) { $quote = '' ; }
        print $file_handle "    value: " . ${quote} . $token . ${quote} . "\n" ;
        next ;
      }

      # Remainder
      $quote = "'";
      $token = $func->variables($var, $property) ;
      $token =~ s/'/''/g ;
      $token =~ s/^''// ;
      $token =~ s/''$// ;
      if ($token =~ /^[0-9]+$/ ) { $quote = '' ; }
      print $file_handle "    ${property}: ${quote}" . $token . "${quote}\n" ;
    }
  }
  print $file_handle "\n" ;

  # Close the file and leave.
  close( $file_handle );
  return 1;
}


#TODO  How should we save namespace information?  We collect the tags... how should we use them?  In maybe a full YAML file with all functions?


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

sub add_variable {
  my $flags = '';
  my $flag_switches = '';
  my $name  = '';
  my $value = '';
  my $scope = 'top';

  # If declare is present, set the local scope and get the flags.
  # Using declare/local allows you to create a variable without specifying a value (otherwise, it'd be seen as a function/command call).
  if ( /^[\s]*(declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*)(${FIRST_VAR_CC}${VAR_CC}*)([=](.*))?/ ) {
    $name  = $4 ;
    $scope = 'local' ;
    if ( $2 ) { $flag_switches .= $2 ; }
    if ( $6 ) { $value          = $6 ; }
    $flag_switches =~ s/[^a-zA-Z]// ;
    foreach my $flag ( split /-/, $flag_switches ) {
      given ($flag) {
        when (/a/) { $flags .= 'array '     ; }
        when (/A/) { $flags .= 'hash '      ; }
        when (/i/) { $flags .= 'integer '   ; }
        when (/l/) { $flags .= 'lowercase ' ; }
        when (/r/) { $flags .= 'readonly '  ; }
        when (/u/) { $flags .= 'uppercase ' ; }
        default    { &print_so_verbose("Found a declare switch I don't have a mapping for: $flag") ; }
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

  # Before we strip spacing see if this is an array without the explicit -a switch.

  # If we still don't have a name, then we need to leave.
  if ( ! $name ) { return 0 ; }

  # Variables can be found multiple times due to assignments.  Scan for existing name and abort if found.
  foreach my $existing_name ( $func->variables() ) {
    if ( $name eq $existing_name ) { return 1 ; }
  }

  # Trim the line-end comments to derive the true default value sent, if any.
  my $in_quote  = '';
  my $escape    = '';
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

  # If the variable's value looks like an array or hash, let's grab it.
  if ($value =~ /^\(/ ) {
    # Assume this is an array for now; we can change our mind later.
    my $inferred_type = 'array ' ;
    # If the value doesn't end in a bare closing parenthesis then this will be multiline.
    if ($value !~ /\)$/ ) {
      $new_value = $value ;
      my $fh;
      my $local_line_no = 0;
      open( $fh, '<', $current_file ) or &fatal($E_IO_FAILURE, "Unable to open file for reading values from:  " . $current_file ) ;
      while( <$fh> ) {
        $local_line_no++;
        chomp ;
        if ($local_line_no <= $line_num) { next ; }
        if ($_ =~ /^[\s]*\[['"]?[a-zA-Z0-9_ -]+['"]?\]=/ ) { $inferred_type = 'hash ' ; }
        $in_quote = '' ;
        $escape   = '' ;
        foreach my $char ( split //, $_ ) {
          $new_value .= $char ;
          if (   $escape                         ) { $escape = ''      ; next ; }
          if ( ! $escape   && $char eq '\\'      ) { $escape = 'yep'   ; next ; }
          if (   $in_quote && $char eq $in_quote ) { $in_quote = ''    ; next ; }
          if ( ! $in_quote && $char =~ /["']/    ) { $in_quote = $char ; next ; }
          if ( ! $in_quote && $char eq '#'       ) { $new_value = substr($new_value, 0, -1) ; last ; }
          if ( ! $in_quote && $char eq ';'       ) { $new_value = substr($new_value, 0, -1) ; last ; }
        }
        if ($_ =~ /\)$/ ){ last ; }
      }
      close($fh) ;
      $value = $new_value ;
    }
    if ($flags !~ /hash/ && $flags !~ /${inferred_type}/ ) { $flags .= "${inferred_type} " ; }
  }

  # If the variable's value is multiline inside quotes and isn't an array or hash try to find it.
  if ($value =~ /^['][^']+$/ || $value =~ /^["][^"]+$/ ) {
    my $fh;
    my $local_line_no = 0;
    my $leading_quote = substr($value, 0, 1) ;
    open( $fh, '<', $current_file ) or &fatal($E_IO_FAILURE, "Unable to open file for reading multiline value from:  " . $current_file ) ;
    while( <$fh> ) {
      $local_line_no++;
      chomp;
      if ($local_line_no <= $line_num) { next ; }
      $value .= "\n" . $_ ;
      if (substr($_, -1, 1) eq $leading_quote) { last ; }
    }
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

  if ( /^[\s]*(while[\s]+)?((core__)?getopts)[\s]+['"](${OPT_CC}*)['"][\s]+['"]?${FIRST_VAR_CC}${VAR_CC}*['"]?([\s]+['"](${OPT_CC}*)['"])?/ ) {
    $GETOPT_TYPE = $2 ;
    $SHORT_OPTS  = $4 ;
    $LONG_OPTS   = $6 ;
    $inside_getopts = "Yep" ;
    $getopts_offset = $func->loop_level();
  }

  # Strip leading colon (supposed to signal internal error handling).
  $SHORT_OPTS && $SHORT_OPTS =~ s/^:// ;
  $LONG_OPTS  && $LONG_OPTS  =~ s/^:// ;

  # Do some checking in case we find a problem
  if ( ! $SHORT_OPTS && ! $LONG_OPTS ) { &print_so_verbose('Found a getopts block, but no long or short options were sent.  Just FYI.') ; return 0 ; }
  if ( $GETOPT_TYPE eq 'core__getopts' && ! $LONG_OPTS ) { &print_so_verbose('Found core__getopts but no long opts were sent.  Just FYI.') ; }

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

  # If we're in getopts we need to set the last_opt_name, if it changed.  Strip quotes from case items to make regex simpler.
  if ( $inside_getopts && /^[\s]*(['"]?${OPT_CC}+['"]?([\s]*\|[\s]*['"]?${OPT_CC}+['"]?)*)[\s]*\)/ ) { $last_opt_name = $1  ; }
  if ( $getopts_offset gt $func->loop_level() ) { $inside_getopts = "" ; }

  # Try to get a tag name and text.  Leave if we don't get a name.
  if ( ! /(?<![\$\{])#@[\S]+/ ) { return 0 ; }
  if ( /(?<![\$\{])#@([\S]+)([\s]+(.*))?/ ) { $tag_name = $1 ; $tag_text = $3 ; }
  if ( ! $tag_name ) { &print_so_verbose("Passed the regex check to ensure this line has a tag, but somehow I can't find a name... odd.") ; return 0 ; }

  # If name is 'opt_', this is an inferred getopts tag.  We need to read current opt, otherwise we're screwed.
  if ( $tag_name eq "opt_" ) {
    if ( ! $last_opt_name ) { &print_se($func->name() . " - Implied opt tag'" . '#@opt_' . "' found, but cannot infer the option name on line $line_num.\n") ; return 0 ; }
    foreach ( split /\|/, $last_opt_name ) {
      s/['"|\s]+//g;
      $func->tags('option', $_, $tag_text . "\n");
    }
    return 1;
  }
  # If the name is 'opt_X' this is an explicit option tag.  Add it.
  if ( $tag_name =~ /^opt_${OPT_CC}+/ ) {
    $func->tags('option', substr($tag_name, 4), $tag_text . "\n");
    return 1;
  }

  # If name is '$@', '$<number>', or '$*' these are argument tags.
  if ( $tag_name eq '$@' || $tag_name eq '$*' || $tag_name =~ /\$[0-9]+/ ) { $func->tags('argument', substr($tag_name, 1), $tag_text . "\n"); return 1; }

  # If name is '$E_' this is an exit/error tag.
  if ( $tag_name eq '$E_' ) {
    if ( /^(.*[\s]+)?(E_(${VAR_CC}+))[=]/ ) { $tag_name .= $2 ; }
    if ( $tag_name eq '$E_' ) { &print_se($func->name() . " - Implied exit tag '" . '#@$E_' . "' found, but no exit constant found at the front of the line on line $line_num.\n") ; return 0 ; }
  }
  if ( $tag_name =~ /\$E_${VAR_CC}+/ ) {
    $func->tags('variable', substr($tag_name, 1), $tag_text . "\n");
    return 1;
  }

  # If name is '$', this is an inferred variable tag.  We need to find '[whitespace]someVar=' to name the tag 'someVar'.
  if ( $tag_name eq '$' ) {
    if ( /^[\s]*(${FIRST_VAR_CC}${VAR_CC}*)[=]/ ) { $tag_name .= $1 ; }
  }
  # If name is still '$', we need to look for a more formal declaration.
  if ( $tag_name eq '$' ) {
    if ( /^[\s]*(declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*)(${FIRST_VAR_CC}${VAR_CC}*)([=](.*))?/ ) {
      $tag_name .= $4 ;
    }
  }
  if ( $tag_name eq '$' ) { &print_se($func->name() . " - Implied variable tag '" . '#@$' . "' found, but no variable found at the front of the line on line $line_num.\n") ; return 0 ; }
  if ( $tag_name =~ /\$E_${VAR_CC}+/ )              { $func->tags('variable', substr($tag_name, 1), $tag_text . "\n"); return 1; }
  if ( $tag_name =~ /\$${FIRST_VAR_CC}${VAR_CC}*/ ) { $func->tags('variable', substr($tag_name, 1), $tag_text . "\n"); return 1; }

  # If the name is 'dep' or 'dependency' then this is a required tool/program.
  if ( $tag_name =~ /^[Dd]ep$/ || $tag_name =~ /^[Dd]ependency$/ ) {
    $func->tags('dependency', 'all', $tag_text . "\n");
    return 1;
  }

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
  print "This program reads shell scripts and finds functions within them.  It then\n";
  print "scrapes the functions for information and puts them into YAML files which\n";
  print "can be output as HTML / MD files.\n";
  print "\n";
  print "Usage  : ./shocker.pl [options] [file1 [file2...]]\n";
  print "Options:\n";
  print "  -d  Set the document directory to read files from.  Defaults to <script_path>/../doc\n";
  print "  -h  Show this help and quit.\n";
  print "  -q  Be quiet about what we're doing.\n";
  print "  -t  Testing (dry run); don't do any real work.  (Internal use mostly)\n";
  print "  -v  Be verbose about what we're doing.\n";

  exit $E_GOOD ;
}
