BEGIN {
  if( occurrence < 1 ) { occurrence = 1 }
  offset = 0
  found = 0
  while ( found < occurrence ) {
    idx = index(substr(haystack, offset + 1), needle) ;
    found++
    offset += idx
  }
  if ( idx == 0 ) { print idx ; exit }
  print offset ;
}
