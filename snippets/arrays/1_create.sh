#!/bin/bash

# Declare an array.
# Separate elements by anything in the $IFS variable!
# Default $IFS ==> ' \t\n'

ary1=('item 1' 'item 2' 'item 3' 'item 4')

ary2=([0]='item 1' [1]='item 2' [2]='item 3' [3]='item 4')

ary3[0]='item 1'
ary3[1]='item 2'
ary3[2]='item 3'
ary3[3]='item 4'

ary4=(
  'item 1'
  'item 2'
  'item 3'
  'item 4'
)

ary5=(        'item 1'               'item 2'
'item 3'
         'item 4')

declare -a ary6=('item 1' 'item 2' 'item 3' 'item 4')

echo "${ary1[@]}"
echo "${ary2[@]}"
echo "${ary3[@]}"
echo "${ary4[@]}"
echo "${ary5[@]}"
echo "${ary6[@]}"
