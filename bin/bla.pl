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

my $func = Function->new();

$func->name("wheee");
print $func->name() . "\n";

undef $func ;
$func = Function->new();
print $func->name() . "\n";
$func->name("dsfidsjfio");
print $func->name() . "\n";

