#!/usr/bin/perl

my $LIB_DIR = "../lib" ;

my @FILES = split("\n", `find $LIB_DIR`) ;

print "@FILES\n" ;

print "$FILES[0]\n";
print "$FILES[1]\n";
print "$FILES[2]\n";
print "$FILES[3]\n";

print "$#FILES\n";
