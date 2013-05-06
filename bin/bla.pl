#!/usr/bin/perl

use lib '.' ;
use Function ;

my $func = Function->new() ;
#my $temp;
#$func->name("bob");
#$temp = $func->name();
#print "$temp\n";
#print $func->name() . "\n";

$func->tags("opt_a", "I am opt a v1.");
$func->tags("opt_a", "I am opt a v2.");
$func->tags("opt_b", "I am opt b v1.");

print $func->tags("opt_a");
print $func->tags("opt_b");
my @yo = $func->tags();
print "@yo" . "\n";
print "$func->tags()" . "\n";
print "@($func->tags())" . "\n";
print "@$func->tags()" . "\n";

#my %stuff;
#$stuff{"one"}="one says hi";
#$stuff{"two"}="two usually does not";
#my @yo = keys %stuff;
#print "@yo" . "\n";
