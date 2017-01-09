#!/bin/bash

# Declare an array.
ary1=('item 1' 'item 2' 'item 3')
ary2=('red' 'blue')


# Copy an array.
ary_copy=("${ary1[@]}")                 # ==> ary_copy=('item 1' 'item 2' 'item 3')
echo "${ary_copy[@]}"                   # ==> echo 'item 1' 'item 2' 'item 3'


# Merge two or more arrays
ary_merged=("${ary1[@]}" "${ary2[@]}")  # ==> ary_merged=('item 1' 'item 2' 'item 3' 'red' 'blue')
echo "${ary_merged[@]}"                 # ==> echo 'item 1' 'item 2' 'item 3' 'red' 'blue'


# Read file contents into array
#   Be wary of this, you need to set $IFS properly to avoid weird behavior like show below.
#   The `mapfile` and `readarray` commands exist in some shells but aren't portable and are situational.
ary_from_file=( $(< some_data) )        # ==> ary_from_file=( item 1
                                        #     item 2
                                        #     item 3 )
echo "${ary_from_file[@]}"              # ==> echo 'item' '1' 'item' '2' 'item' '3'
echo "${#ary_from_file[@]}"             # ==> echo '6'
unset ary_from_file
IFS=$'\n'
ary_from_file=( $(< some_data) )        # ==> ary_from_file=( item 1
                                        #     item 2
                                        #     item 3 )
echo "${ary_from_file[@]}"              # ==> echo 'item 1' 'item 2' 'item 3'
echo "${#ary_from_file[@]}"             # ==> echo '3'
