#!/bin/bash

# Declare an array.
ary=('item 1' 'ITeM 2' 'iTem 3')

# After you've specified 1 or more elements, all normal
# variable string manipulation works the same.
echo "${ary[2]: 1: 3}"   # ==> echo 'Tem'
echo "${ary[2]: -3: 2}"  # ==> echo 'm '
echo "${ary[2]^^}"       # ==> echo 'ITEM 3'
echo "${ary[2]^}"        # ==> echo 'ITem 3'
echo "${ary[2],,}"       # ==> echo 'item 3'
echo "${ary[2],}"        # ==> echo 'iTem 3'
echo "${ary[2]~}"        # ==> echo 'ITem 3'
echo "${ary[@]~~}"       # ==> echo 'ITEM 1' 'itEm 2' 'ItEM 3'
echo "${ary[0]/item/hi}" # ==> echo 'hi 1'
echo "${ary[@]//e/}"     # ==> echo 'itm 1' 'ITM 2' 'iTm 3'
echo "${ary[@]//[tT]/}"  # ==> echo 'iem 1' 'IeM 2' 'iem 3'
