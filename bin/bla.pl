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

my $func ;
$func = Function->new();

while(<>) {
  #my $tag_name ;
  #my $tag_text = "" ;

  # Try to get a tag name and text.  Leave if we don't get a name.
  #if ( ! /#@[\S]+/ ) { return 0 ; }
  #if ( /#@([\S]+)([\s]+(.*))?/ ) { $tag_name = $1 ; $tag_text = $3 ; }

  if ( /^[\s]*([a-zA-Z_][a-zA-Z0-9_]*)[=]/ ) { print $1 . "\n" ; }
  if ( /^[\s]*(declare[\s]+(-[a-zA-Z][\s]+)+)?local[\s]+([a-zA-Z_][a-zA-Z0-9_]*)/ ) { print $3 . "\n" ; }

}

exit 0;
