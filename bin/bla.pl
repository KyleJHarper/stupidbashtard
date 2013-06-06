#!/usr/bin/perl

while (<>) {
  chomp;

  if ( /^[\s]*$/ ) { print "Skipping a line\n" ; next ; }
  if ( /^[\s]*#@/ ) { print "This line has a tag\n" ; next ; }

  print "Before: " . $_ . "\n" ;
  s/[\s]*#(?!@).*// ;

  print "After: " . $_ . "\n" ;
}
