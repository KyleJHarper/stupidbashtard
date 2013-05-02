#!/usr/bin/perl

my $line = "  function whee {\n";
chomp $line;
my @tokens = split(" ", $line);

foreach ( @tokens ) { print $_ ; }
