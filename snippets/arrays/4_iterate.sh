#!/bin/bash

# Declare an array.
ary=('item 1' 'item 2')

# Use for loop to iterate. ALWAYS ALWAYS ALWAYS DOUBLE QUOTE AND USE @
item=''
printf '%s\n' '[Looping with "" and @ like we should.]'
for item in "${ary[@]}" ; do   # ==> for item in 'item 1' 'item 2'
  echo "${item}"
done

printf '\n%s\n' '[Looping with just @, sad panda.]'
for item in ${ary[@]} ; do     # ==> for item in item 1 item 2
  echo "${item}"
done

printf '\n%s\n' '[Looping with * because we like headaches.]'
for item in "${ary[*]}" ; do   # ==> for item in 'item 1 item 2'
  echo "${item}"
done

# Reverse an array
printf '\n%s\n' '[Reverse an array and store it]'
ary_rev=()
for item in "${ary[@]}" ; do
  ary_rev=("${item}" "${ary_rev[@]}")
done
echo "${ary_rev[@]}"   # ==> echo 'item 2' 'item 1'

