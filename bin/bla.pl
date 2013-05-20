#!/usr/bin/perl

my $bla ;
$bla = "hello" ;
print $bla . "\n" ;

my $bla ;
print $bla . "\n" ;
exit 0 ;

# Try to get a tag name and text.  Leave if we don't get a name.
while (<>) {
  if ( /#@([\S]*)[\s]+(.*)/ ) { &add_tag ; }
}

sub add_tag {
  my $tag_name ;
  my $tag_text ;

  # Try to get a tag name and text.  Leave if we don't get a name.
  if ( /#@([\S]*)[\s]+(.*)/ ) { $tag_name = $1 ; $tag_text = $2 ; }
  print "tag_name: ". $tag_name . "\n";
  print "tag_text: ". $tag_text . "\n";
}


# OLD
#use lib '.' ;
#use Function ;

#my $func = Function->new() ;
#my $temp;
#$func->name("bob");
#$temp = $func->name();
#print "$temp\n";
#print $func->name() . "\n";

#$func->tags("opt_a", "I am opt a v1.");
#$func->tags("opt_a", "I am opt a v2.");
#$func->tags("opt_b", "I am opt b v1.");

#print $func->tags("opt_a");
#print $func->tags("opt_b");
#my @yo = $func->tags();
#print "@yo" . "\n";
#print "$func->tags()" . "\n";
#print "@($func->tags())" . "\n";
#print "@$func->tags()" . "\n";

#my %stuff;
#$stuff{"one"}="one says hi";
#$stuff{"two"}="two usually does not";
#my @yo = keys %stuff;
#print "@yo" . "\n";
