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
  @FLAGS = ();
  $FLAG_SWITCHES = '';
  $NAME  = '';
  $VALUE = '';
  $SCOPE = 'top';

  # If declare is present, let's set the local scope and get the flags.  Allow 2x declare/local combo since bash does... ugh.
  # Using declare/local allows you to create a variable without specifying a value (otherwise, it'd be seen as a function/command call).
  if ( /^[\s]*(declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*)((declare|typeset|local)[\s]+((-[a-zA-Z][\s]+)*))?(${FIRST_VAR_CC}${VAR_CC}*)([=](.*))?/ ) {
    $NAME  = $8 ;
    $SCOPE = 'local' ;
    if (  $2 ) { $FLAG_SWITCHES .=  $2 ; }
    if (  $6 ) { $FLAG_SWITCHES .=  $6 ; }
    if ( $10 ) { $VALUE          = $10 ; }
    $FLAG_SWITCHES =~ s/[^a-zA-Z]// ;
    foreach my $flag ( split /-/, $FLAG_SWITCHES ) {
      switch ($flag) {
        case /a/  { push(@FLAGS, 'array') ; }
        case /A/  { push(@FLAGS, 'hash') ; }
        case /i/  { push(@FLAGS, 'integer') ; }
        case /l/  { push(@FLAGS, 'lowercase') ; }
        case /r/  { push(@FLAGS, 'readonly') ; }
        case /u/  { push(@FLAGS, 'uppercase') ; }
        else      { &print_so_verbose("Found a declare switch I don't have a mapping for: $flag") ; }
      }
    }
  }

  # If we don't have a name yet, then we need to scan for a non-local variable.  It must have a value assigned or it'll be interpreted as
  # a command or function call.
  if ( ! $NAME ) {
    if ( /^[\s]*(${FIRST_VAR_CC}${VAR_CC}*)[=](.*)/ ) {
      $NAME  = $1 ;
      $VALUE = $2 ;
    }
  }

  # If we still don't have a name, then we need to leave.
  if ( ! $NAME ) { next ; }

  # Trim the line-end comments to derive the true default value sent, if any.
  my $in_quote = '';
  my $escape   = '';
  my $new_value = '';
  foreach my $char ( split //, $VALUE ) {
    $new_value .= $char ;
    if (   $escape                         ) { $escape = ''      ; next ; }
    if ( ! $escape   && $char eq '\\'      ) { $escape = 'yep'   ; next ; }
    if (   $in_quote && $char eq $in_quote ) { $in_quote = ''    ; next ; }
    if ( ! $in_quote && $char =~ /["']/    ) { $in_quote = $char ; next ; }
    if ( ! $in_quote && $char eq '#'       ) { $new_value = substr($new_value, 0, -1) ; last ; }
  }
  $VALUE = $new_value;
  $VALUE =~ s/^[\s]*//g    ;
  $VALUE =~ s/[\s]*$//g    ;
  # Load the info into our function object.
  print "Name: $NAME   Scope: $SCOPE    Flags: @FLAGS    Value: '$VALUE'\n";
}



sub print_so_verbose {
  if ( $VERBOSE ) { print "@_\n" ; return 0 ; }
}

exit 0;
