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



my $stuff = "local declare -A E_HOWDY=134";
if ( $stuff =~ /^(.*[\s]+)?(E_[a-zA-Z0-9_]+)[=]/ ) { print $2 . "\n" ; }

my $stuff = "local E_HOWDY=134";
if ( $stuff =~ /^(.*[\s]+)?(E_[a-zA-Z0-9_]+)[=]/ ) { print $2 . "\n" ; }

my $stuff = "declare -A E_HOWDY=134";
if ( $stuff =~ /^(.*[\s]+)?(E_[a-zA-Z0-9_]+)[=]/ ) { print $2 . "\n" ; }

my $stuff = "declare -A local E_HOWDY=134";
if ( $stuff =~ /^(.*[\s]+)?(E_[a-zA-Z0-9_]+)[=]/ ) { print $2 . "\n" ; }


exit 0;


my $func = Function->new();
my %defaults            ;
$defaults{"Author"} = ""      ;
$defaults{"Date"} = ""        ;
$defaults{"Version"} = ""     ;
$defaults{"Namespace"} = ""   ;
$defaults{"Description"} = "" ;


$func->variable_tags("chicka", "bow wow");

  if ( $func->basic_tags("Author") eq "" )      { $func->basic_tags("Author",      $defaults{"Author"})      ; }
  if ( $func->basic_tags("Date") eq "" )        { $func->basic_tags("Date",        $defaults{"Date"})        ; }
  if ( $func->basic_tags("Version") eq "" )     { $func->basic_tags("Version",     $defaults{"Version"})     ; }
  if ( $func->basic_tags("Namespace") eq "" )   { $func->basic_tags("Namespace",   $defaults{"Namespace"})   ; }
  if ( $func->basic_tags("Description") eq "" ) { $func->basic_tags("Description", $defaults{"Description"}) ; }

print $func->variable_tags() ;
exit 0;




$func->count_braces("some text");
$func->count_braces("function bob {");
print "Opened braces: " .$func->opened_braces() . "\n" ;
print "Closed braces: " .$func->closed_braces() . "\n" ;

undef $func ;
$func = Function->new();
$func->count_braces("some text");
$func->count_braces("function bob {");
$func->count_braces("}");
print "Opened braces: " .$func->opened_braces() . "\n" ;
print "Closed braces: " .$func->closed_braces() . "\n" ;

exit 0;







$func->name("wheee");
print $func->name() . "\n";

undef $func ;
$func = Function->new();
print $func->name() . "\n";
$func->name("dsfidsjfio");
print $func->name() . "\n";

