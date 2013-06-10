#!/usr/bin/perl

if ( 1 ge 3 - 1 ) { print "hello\n" ; }

exit ;

while (<>) {
  chomp;

  if ( /^[\s]*$/ ) { print "Skipping a line\n" ; next ; }
  if ( /^[\s]*#@/ ) { print "This line has a tag\n" ; next ; }

  print "Before: " . $_ . "\n" ;
  s/[\s]*#(?!@).*// ;

  print "After: " . $_ . "\n" ;
}
