{
  rev_str = ""
  for ( i=length($0); i > 0; i-- ) {
    rev_str = rev_str substr($0, i, 1)
  }
  print rev_str
}
