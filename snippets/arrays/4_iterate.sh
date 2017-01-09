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


# Work on array in reverse without storing it like above.
printf '\n%s\n' '[Operate on array in reverse without storing it]'
ary_with_holes=('item 1' 'item 2' 'item 3' 'item 4' 'item 5')
unset ary_with_holes[2]
unset ary_with_holes[4]
highest_index=0
for index in "${!ary_with_holes[@]}" ; do
  [ ${index} -gt ${highest_index} ] && highest_index=${index}
done
for (( i=${highest_index}; i>=0; i-- )) ; do
  if [ "${ary_with_holes[$i]+i am real}" == 'i am real' ] ; then
    echo "I went in reverse... ${ary_with_holes[$i]}"
    # Do whatever logic you want here...
  fi
done

