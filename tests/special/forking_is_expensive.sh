#!/bin/bash

function add_main {
  let "some_var += ${NUM}"
}

function add_eval {
  local temp=$1
  eval let $temp+=${NUM}
}

function add_subshell {
  local temp=$1
  let "temp += ${NUM}"
  echo "$temp"
}

function new_test {
  printf '%-30s%1s' "| $1" '|'
  i=1
  some_var=0
  START=$(date +%s%N)
}

function print_title {
  echo "Adding the number ${NUM} to itself ${MAX} times."
  #                 0        1         2         3         4         5         6
  #                 123456789012345678901234567890123456789012345678901234567890
  printf '%-43s\n' '+---------------------------------------------------+'
  printf '%-43s\n' '| Test Name                   | Time ms | % of main |'
  printf '%-43s\n' '+---------------------------------------------------+'
}

function print_results {
  END=$(date +%s%N)
  total=$(( $END - $START ))
  let "total /= 1000000"
  [ $MAIN_RUN_TIME -eq 0 ] && MAIN_RUN_TIME=${total}
  if [ ${some_var} -ne ${FINAL} ] ; then echo "Values don't match." ; exit 1 ; fi
  printf '%8d%3s' "$total" ' | '
  printf '%8.2f%%%3s\n' "$(echo "scale=2; 100 * $total / ${MAIN_RUN_TIME}" | bc )" ' | '
}

function print_footer {
  printf '%-43s\n' '+---------------------------------------------------+'
}

# Test params
MAX=5000
NUM=23
FINAL=$(( ${MAX} * ${NUM} ))
MAIN_RUN_TIME=0

print_title

# -- Test 1
new_test 'Using main thread'
while [ $i -le $MAX ] ; do let some_var+=${NUM} ; let i++ ; done
print_results

# -- Test 2
new_test 'Using a function'
while [ $i -le $MAX ] ; do add_main ; let i++ ; done
print_results

# -- Test 3
new_test 'Using a function & eval'
while [ $i -le $MAX ] ; do add_eval 'some_var' ; let i++ ; done
print_results

# -- Test 4
new_test 'Using a subshell'
while [ $i -le $MAX ] ; do some_var=$(add_subshell ${some_var}) ; let i++ ; done
print_results

print_footer
