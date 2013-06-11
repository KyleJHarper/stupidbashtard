#!/usr/bin/perl

my $fh;

open($fh, '>>', "testfile.out");

print $fh "Some output" . " and more";

close($fh);
