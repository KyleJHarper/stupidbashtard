#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

# Source shared, core, and namespace.
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../__shared.inc.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/core.sh"
. "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../sbt/array.sh"


# Performance check
if [ "${1}" == 'performance' ] ; then iteration=1 ; START="$(date '+%s%N')" ; else echo '' ; fi


# Testing loop
declare -a myArray=('one' 'two has spaces' 'three' 'four' 'five space' 'six' 'seven')
declare -A myAssoc=(['one']='orange' ['two']='apple seeds' ['three']='grapes' ['fourth element']='ok now')
while [ ${iteration} -le ${MAX_ITERATIONS} ] ; do
  # -- 1 -- Simple test to get keys from an array.
  unset output
  declare -a output
  new_test "Trying to get keys from a normal array: "
  array__keys -a 'myArray' -R 'output'
  [ "${output[*]}" = '0 1 2 3 4 5 6' ]    || fail 1
  [ ${#output[@]} -eq 7 ]                 || fail 2
  pass

  # -- 2 -- Simple test to get keys from an associative array.
  unset output
  declare -a output
  new_test "Trying to get keys from an associative array: "
  array__keys -a 'myAssoc' -R 'output'
  [ ${#output[@]} -eq 4 ]    || fail 1
  pass

  # -- 3 -- Long option should work
  unset output
  declare -a output
  new_test "Using the long option formats should work fine: "
  array__keys --array 'myArray' -R 'output'
  [ "${output[*]}" = '0 1 2 3 4 5 6' ]    || fail 1
  [ ${#output[@]} -eq 7 ]                 || fail 2
  pass

  # -- 4 -- Not sending an array name should fail.
  unset output
  declare -a output
  new_test "Failure to send an array to read keys from should fail: "
  array__keys -R 'output'    2>/dev/null   && fail 1
  pass

  # -- 5 -- Not sending an output array to store results in should fail.
  unset output
  declare -a output
  new_test "Failure to send an output array to store results in should fail: "
  array__keys -a 'myArray'   2>/dev/null   && fail 1
  pass


  let iteration++
done


# Send final data
if [ "${1}" == 'performance' ] ; then
  END="$(date '+%s%N')"
  let "TOTAL = (${END} - ${START}) / 1000000"
  printf "  %'.0f tests in %'.0f ms (%s tests/sec)\n" "${test_number}" "${TOTAL}" "$(bc <<< "scale = 3; ${test_number} / (${TOTAL} / 1000)")" >&2
fi

