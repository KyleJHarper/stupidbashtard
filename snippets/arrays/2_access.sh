#!/bin/bash

# Declare an array.
declare -a my_array=('item 1' 'item 2' 'item 3')


# Print a single element
echo "${my_array[0]}"      # ==> echo 'item 1'

# Print all elements, separated by first character of IFS.
echo "${my_array[*]}"      # ==> echo 'item 1 item 2 item 3'

# Print all elements, extrapolated as individual arguments
echo "${my_array[@]}"      # ==> echo 'item 1' 'item 2' 'item 3'

# Print a negative element index (array reversal)
echo "${my_array[-1]}"     # ==> echo 'item 3'

# Print a range of elements.
echo "${my_array[@]:1:2}"  # ==> echo 'item 2' 'item 3'

# Show number of elements in array
echo "${#my_array[@]}"     # ==> echo '3'

# Print the element indexes, not their values.
echo "${!my_array[@]}"     # ==> echo '0' '1' '2'

# Print element with another variable as the subscript.
x=1
echo "${my_array[$x]}"     # ==> echo 'item 2'
