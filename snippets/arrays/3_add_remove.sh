#!/bin/bash

# Declare an array.
ary=('item 1' 'item 2' 'item 3')

# Add item to end of array.
ary+=('item 4')
ary[99]='item 100'
echo "${#ary[@]}"  # ==> echo '5'

# Remove item from array (changes length, but doesn't *pop*)
unset ary[2]
echo "${#ary[@]}"  # ==> echo '4'
echo "${ary[2]}"   # ==> echo ''
echo "${ary[@]}"   # ==> echo 'item 1' 'item 2' 'item 4' 'item 100'
echo "${!ary[@]}"  # ==> echo '0' '1' '3' '99'

# Adding new elements will NOT fill in unset slots (like ary[2] above)
ary+=('will I go into subscript 2 since it is open?')
echo "${!ary[@]}"  # ==> echo '0' '1' '3' '99' '100'
echo "${ary[2]}"   # ==> echo ''

# Delete entire array.
unset ary
echo "${#ary[@]}"  # ==> echo '0'
echo "${ary[@]}"   # ==> echo ''

# Add new items to the front of the array
unset ary
ary=('red' 'blue')
ary=('white' "${ary[@]}")  # ==> ary=('white' 'red' 'blue')
echo "${ary[@]}"           # ==> echo 'white' 'red' 'blue'

# Insert item into array index (assuming array has no holes!)
unset ary
ary=('red' 'blue' 'green')
x=1
ary=("${ary[@]: 0: $x}" 'white' "${ary[@]: $x}")  # ==> ary=('red' 'white' 'blue' 'green')
echo "${ary[@]}"                                  # ==> echo 'red' 'white' 'blue' 'green'
